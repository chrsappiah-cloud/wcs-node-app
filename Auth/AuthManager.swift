import AuthenticationServices
import CryptoKit
import Foundation
import UIKit

// MARK: - Auth State

enum AuthState: Equatable {
    case idle
    case loading
    case awaitingOtp(phone: String)
    case authenticated
    case error(String)
}

// MARK: - AuthManager

/// Single source of truth for the sign-in lifecycle.
/// Handles phone OTP, Apple Sign In, and Google OAuth (via ASWebAuthenticationSession).
/// Session is persisted to the Keychain between launches.
@MainActor
final class AuthManager: NSObject, ObservableObject {

    // MARK: Published

    @Published var state: AuthState = .idle
    @Published var session: AuthSession?

    // MARK: Private

    private let keychain = AuthKeychain()
    private let apiBase: String

    // Google OAuth PKCE state
    private var googleCodeVerifier: String?
    private var googleAuthSession: ASWebAuthenticationSession?

    // Apple credential request coordinator
    private var appleCompletion: ((Result<AuthSession, Error>) -> Void)?
    private var appleNonce: String?

    // MARK: Init

    override init() {
        let configured = Bundle.main.object(forInfoDictionaryKey: "GeoWCSAPIBase") as? String
        apiBase = configured ?? "http://localhost:3000"
        super.init()
        session = keychain.loadSession()
    }

    // MARK: - Sign Out

    func signOut() {
        keychain.deleteSession()
        session = nil
        state = .idle
    }

    // MARK: - Phone OTP

    /// Validates E.164 format and requests an OTP from the backend.
    func sendOtp(phone: String) async {
        guard isValidE164(phone) else {
            state = .error("Enter a valid phone number including country code (e.g. +14155552671)")
            return
        }

        state = .loading
        do {
            let _: SendOtpResponse = try await post(
                path: "/v1/auth/phone/send-otp",
                body: ["phone": phone]
            )
            state = .awaitingOtp(phone: phone)
        } catch {
            state = .error(errorMessage(from: error))
        }
    }

    /// Verifies the 6-digit OTP and completes sign-in.
    func verifyOtp(phone: String, code: String) async {
        guard code.count == 6, code.allSatisfy(\.isNumber) else {
            state = .error("Enter the 6-digit code from your SMS")
            return
        }

        state = .loading
        do {
            let response: TokenResponse = try await post(
                path: "/v1/auth/phone/verify-otp",
                body: ["phone": phone, "code": code]
            )
            let s = AuthSession(
                userId: phone,
                authMethod: .phone,
                displayName: phone,
                phoneNumber: phone,
                email: nil,
                bearerToken: response.token,
                consentGrantedAt: nil,
                tier: .free
            )
            persist(session: s)
        } catch {
            state = .error(errorMessage(from: error))
        }
    }

    // MARK: - Apple Sign In

    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()

        let rawNonce = randomNonceString()
        appleNonce = rawNonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(rawNonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - Google OAuth (PKCE via ASWebAuthenticationSession)

    func signInWithGoogle(from windowScene: UIWindowScene? = nil) {
        guard let clientId = Bundle.main.object(forInfoDictionaryKey: "GoogleClientID") as? String,
              !clientId.isEmpty else {
            state = .error("Google Client ID is not configured in Info.plist")
            return
        }

        let verifier = randomNonceString(length: 64)
        googleCodeVerifier = verifier
        let challenge = base64URLEncode(sha256Data(verifier))

        let redirectScheme = "com.googleusercontent.apps.\(clientId)"
        let redirectURI = "\(redirectScheme):/oauth2redirect"

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            .init(name: "client_id",             value: "\(clientId).apps.googleusercontent.com"),
            .init(name: "redirect_uri",           value: redirectURI),
            .init(name: "response_type",          value: "code"),
            .init(name: "scope",                  value: "openid email profile"),
            .init(name: "code_challenge",         value: challenge),
            .init(name: "code_challenge_method",  value: "S256")
        ]

        guard let authURL = components.url else {
            state = .error("Could not build Google auth URL")
            return
        }

        state = .loading

        googleAuthSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: redirectScheme
        ) { [weak self] callbackURL, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.state = .error(self.errorMessage(from: error))
                    return
                }
                guard let code = URLComponents(url: callbackURL!, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "code" })?.value
                else {
                    self.state = .error("Google auth response missing code")
                    return
                }
                await self.exchangeGoogleCode(code: code, redirectURI: redirectURI, clientId: clientId)
            }
        }
        googleAuthSession?.presentationContextProvider = self as? ASWebAuthenticationPresentationContextProviding
        googleAuthSession?.prefersEphemeralWebBrowserSession = true
        googleAuthSession?.start()
    }

    // MARK: - Consent

    /// Must be called before enabling location sharing.
    func grantConsent() {
        guard var s = session else { return }
        s.consentGrantedAt = Date()
        persist(session: s)
    }

    func revokeConsent() {
        guard var s = session else { return }
        s.consentGrantedAt = nil
        persist(session: s)
    }

    var hasConsent: Bool { session?.consentGrantedAt != nil }

    // MARK: - Private helpers

    private func exchangeGoogleCode(code: String, redirectURI: String, clientId: String) async {
        guard let verifier = googleCodeVerifier else { return }
        googleCodeVerifier = nil

        do {
            // Exchange auth code for tokens at Google's token endpoint
            let tokenRes: GoogleTokenResponse = try await post(
                url: URL(string: "https://oauth2.googleapis.com/token")!,
                body: [
                    "code": code,
                    "client_id": "\(clientId).apps.googleusercontent.com",
                    "redirect_uri": redirectURI,
                    "code_verifier": verifier,
                    "grant_type": "authorization_code"
                ],
                useFormEncoded: true
            )

            // Send the id_token to our backend for verification + JWT issue
            let resp: TokenResponse = try await post(
                path: "/v1/auth/google",
                body: ["idToken": tokenRes.id_token]
            )

            let s = AuthSession(
                userId: tokenRes.id_token, // verified/replaced server-side
                authMethod: .google,
                displayName: "Google User",
                phoneNumber: nil,
                email: tokenRes.id_token,
                bearerToken: resp.token,
                consentGrantedAt: nil,
                tier: .free
            )
            persist(session: s)
        } catch {
            state = .error(errorMessage(from: error))
        }
    }

    private func persist(session: AuthSession) {
        self.session = session
        keychain.saveSession(session)
        state = .authenticated
    }

    // MARK: - HTTP

    private func post<ResponseBody: Decodable>(
        path: String,
        body: [String: String]
    ) async throws -> ResponseBody {
        let url = URL(string: "\(apiBase)\(path)")!
        return try await post(url: url, body: body, useFormEncoded: false)
    }

    private func post<ResponseBody: Decodable>(
        url: URL,
        body: [String: String],
        useFormEncoded: Bool
    ) async throws -> ResponseBody {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15

        if useFormEncoded {
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = body.map { k, v in
                "\(k)=\(v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? v)"
            }.joined(separator: "&").data(using: .utf8)
        } else {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(http.statusCode) else {
            let msg = (try? JSONDecoder().decode(APIError.self, from: data))?.message
                ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            throw AuthError.serverError(msg)
        }

        return try JSONDecoder().decode(ResponseBody.self, from: data)
    }

    // MARK: - Validation

    private func isValidE164(_ phone: String) -> Bool {
        let pattern = #"^\+[1-9]\d{6,14}$"#
        return phone.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Crypto helpers

    private func randomNonceString(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        let _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .prefix(length)
            .description
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func sha256Data(_ input: String) -> Data {
        let data = Data(input.utf8)
        return Data(SHA256.hash(data: data))
    }

    private func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func errorMessage(from error: Error) -> String {
        if let authErr = error as? AuthError { return authErr.localizedDescription }
        return error.localizedDescription
    }
}

// MARK: - Apple Sign In Delegates

extension AuthManager: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = cred.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8)
        else {
            Task { @MainActor in self.state = .error("Apple credential missing identity token") }
            return
        }

        let fullName = [cred.fullName?.givenName, cred.fullName?.familyName]
            .compactMap { $0 }.joined(separator: " ")

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.state = .loading
            do {
                let resp: TokenResponse = try await self.post(
                    path: "/v1/auth/apple",
                    body: ["identityToken": identityToken]
                )
                let s = AuthSession(
                    userId: cred.user,
                    authMethod: .apple,
                    displayName: fullName.isEmpty ? "Apple User" : fullName,
                    phoneNumber: nil,
                    email: cred.email,
                    bearerToken: resp.token,
                    consentGrantedAt: nil,
                    tier: .free
                )
                self.persist(session: s)
            } catch {
                self.state = .error(self.errorMessage(from: error))
            }
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let code = (error as? ASAuthorizationError)?.code
        guard code != .canceled else { return }
        Task { @MainActor in self.state = .error(error.localizedDescription) }
    }
}

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first { $0.isKeyWindow }
            ?? UIWindow()
    }
}

// MARK: - Supporting types

private struct SendOtpResponse: Decodable { let sent: Bool }
private struct TokenResponse: Decodable { let token: String }
private struct GoogleTokenResponse: Decodable { let id_token: String }
private struct APIError: Decodable { let message: String }

enum AuthError: LocalizedError {
    case serverError(String)
    var errorDescription: String? {
        if case .serverError(let msg) = self { return msg }
        return "Authentication failed"
    }
}

// MARK: - Keychain persistence

private final class AuthKeychain {
    private let service = "com.geowcs.auth"
    private let account = "session"

    func saveSession(_ session: AuthSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func loadSession() -> AuthSession? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return try? JSONDecoder().decode(AuthSession.self, from: data)
    }

    func deleteSession() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
