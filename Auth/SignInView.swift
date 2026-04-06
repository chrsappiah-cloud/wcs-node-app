import AuthenticationServices
import SwiftUI

/// Landing sign-in screen. Shown when no authenticated session exists.
struct SignInView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var showPhone = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGroupedBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Mark / Logo
                    VStack(spacing: 12) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 64, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .teal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("GeoWCS")
                            .font(.system(size: 34, weight: .bold, design: .rounded))

                        Text("Share your location with\npeople you trust.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    if !authManager.configurationWarnings.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Auth Setup Required", systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.orange)

                            ForEach(authManager.configurationWarnings, id: \.self) { warning in
                                Text("• \(warning)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 28)
                        .padding(.top, 20)
                    }

                    Spacer()

                    // Auth buttons
                    VStack(spacing: 14) {
                        // Apple Sign In — uses official SAAuthorizationAppleIDButton via UIViewRepresentable
                        AppleSignInButton()
                            .frame(height: 52)
                            .cornerRadius(12)
                            .accessibilityIdentifier("Continue with Apple")
                            .onTapGesture {
                                authManager.signInWithApple()
                            }

                        // Google Sign In
                        Button {
                            authManager.signInWithGoogle()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "globe")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Continue with Google")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(.systemBlue))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .accessibilityIdentifier("Continue with Google")
                        .buttonStyle(.plain)

                        // Phone
                        Button {
                            showPhone = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Continue with Phone")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color(.separator), lineWidth: 0.5)
                            )
                        }
                        .accessibilityIdentifier("Continue with Phone")
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 28)

                    // Legal copy
                    Text("By continuing you agree to our [Terms](https://geowcs.app/terms) and [Privacy Policy](https://geowcs.app/privacy).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                        .padding(.bottom, 36)
                }

                // Loading overlay
                if case .loading = authManager.state {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.4)
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
            }
            .navigationDestination(isPresented: $showPhone) {
                PhoneVerificationView()
                    .environmentObject(authManager)
            }
            .onChange(of: authManager.state) { _, newState in
                if case .error(let msg) = newState {
                    errorMessage = msg
                    showErrorAlert = true
                }
            }
            .onAppear {
                authManager.refreshConfigurationWarnings()
            }
            .alert("Sign In Failed", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Apple Sign In Button (UIKit bridge)

/// Wraps ASAuthorizationAppleIDButton to match SwiftUI layout.
private struct AppleSignInButton: UIViewRepresentable {
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        ASAuthorizationAppleIDButton(type: .continue, style: .black)
    }

    func updateUIView(_ view: ASAuthorizationAppleIDButton, context: Context) {}
}
