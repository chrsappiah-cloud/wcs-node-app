import SwiftUI

/// Two-step phone authentication:
/// 1. Enter phone number (country picker + number field)
/// 2. Enter 6-digit OTP
struct PhoneVerificationView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    // Step 1: Phone entry
    @State private var countryCode = "+1"
    @State private var phoneSuffix = ""
    @State private var showCountryPicker = false

    // Step 2: OTP entry
    @State private var otp = ["", "", "", "", "", ""]
    @FocusState private var otpFocus: Int?

    // Error alert
    @State private var errorMessage = ""
    @State private var showError = false

    private var step: PhoneStep {
        if case .awaitingOtp = authManager.state { return .otp }
        return .phone
    }

    private var e164Phone: String {
        let digits = phoneSuffix.filter(\.isNumber)
        return "\(countryCode)\(digits)"
    }

    private var phoneReady: Bool {
        let digits = phoneSuffix.filter(\.isNumber)
        return digits.count >= 7 && digits.count <= 15
    }

    private var otpString: String { otp.joined() }
    private var otpComplete: Bool { otp.allSatisfy { $0.count == 1 } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Step indicator
                PhoneStepHeader(step: step)
                    .padding(.bottom, 32)

                if step == .phone {
                    phoneEntryBody
                } else {
                    otpEntryBody
                }

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .navigationTitle("Phone Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showCountryPicker) {
                CountryPickerView(selected: $countryCode)
            }
            .onChange(of: authManager.state) { _, newState in
                if case .error(let msg) = newState {
                    errorMessage = msg
                    showError = true
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: Step 1 — Phone

    private var phoneEntryBody: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Enter your phone number")
                .font(.title2.bold())

            Text("We'll send you a one-time code to verify your number.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                // Country code picker
                Button {
                    showCountryPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(countryCode)
                            .font(.body.monospacedDigit())
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .foregroundColor(.primary)
                }
                .buttonStyle(.plain)

                // Phone number field
                TextField("Phone number", text: $phoneSuffix)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .font(.body.monospacedDigit())
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .accessibilityIdentifier("Phone Number")
            }

            Text("e.g. 415 555 2671")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Button {
                Task { await authManager.sendOtp(phone: e164Phone) }
            } label: {
                label(text: "Send Verification Code", loading: authManager.state == .loading)
            }
            .accessibilityIdentifier("Send Verification Code")
            .disabled(!phoneReady || authManager.state == .loading)
        }
    }

    // MARK: Step 2 — OTP

    private var otpEntryBody: some View {
        let phone: String = {
            if case .awaitingOtp(let p) = authManager.state { return p }
            return e164Phone
        }()

        return VStack(alignment: .leading, spacing: 24) {
            Text("Enter 6-digit code")
                .font(.title2.bold())

            Text("We sent a 6-digit code to **\(phone)**.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // OTP digit boxes
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { idx in
                    OTPDigitField(
                        digit: $otp[idx],
                        index: idx,
                        focus: $otpFocus,
                        onFill: { advanceOtpFocus(from: idx) }
                    )
                }
            }

            Button {
                Task { await authManager.verifyOtp(phone: phone, code: otpString) }
            } label: {
                label(text: "Verify", loading: authManager.state == .loading)
            }
            .accessibilityIdentifier("Verify")
            .disabled(!otpComplete || authManager.state == .loading)

            // Resend
            Button {
                otp = ["", "", "", "", "", ""]
                Task { await authManager.sendOtp(phone: phone) }
            } label: {
                Text("Resend code")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .onAppear { otpFocus = 0 }
    }

    // MARK: Helpers

    private func advanceOtpFocus(from index: Int) {
        let next = index + 1
        if next < 6 { otpFocus = next }
        else { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
    }

    @ViewBuilder
    private func label(text: String, loading: Bool) -> some View {
        HStack {
            if loading { ProgressView().tint(.white) }
            Text(text).font(.system(size: 17, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(12)
    }
}

// MARK: - OTP digit box

private struct OTPDigitField: View {
    @Binding var digit: String
    let index: Int
    var focus: FocusState<Int?>.Binding
    let onFill: () -> Void

    var body: some View {
        TextField("", text: $digit)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .multilineTextAlignment(.center)
            .font(.title2.monospacedDigit().bold())
            .frame(width: 46, height: 56)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .focused(focus, equals: index)
            .onChange(of: digit) { _, val in
                let filtered = val.filter(\.isNumber)
                if filtered.count > 1 {
                    digit = String(filtered.suffix(1))
                } else {
                    digit = filtered
                }
                if digit.count == 1 { onFill() }
            }
    }
}

// MARK: - Step header

private enum PhoneStep { case phone, otp }

private struct PhoneStepHeader: View {
    let step: PhoneStep

    var body: some View {
        HStack(spacing: 8) {
            stepDot(label: "1", active: step == .phone)
            Rectangle().frame(height: 1).foregroundStyle(step == .otp ? .blue : Color(uiColor: .separator))
            stepDot(label: "2", active: step == .otp)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func stepDot(label: String, active: Bool) -> some View {
        ZStack {
            SwiftUI.Circle()
                .fill(active ? Color.blue : Color(.secondarySystemBackground))
                .frame(width: 28, height: 28)
            Text(label)
                .font(.caption.bold())
                .foregroundColor(active ? .white : .secondary)
        }
    }
}

// MARK: - Country picker

private struct CountryPickerView: View {
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss

    private let countries: [(flag: String, code: String, name: String)] = [
        ("🇺🇸", "+1",   "United States"),
        ("🇬🇧", "+44",  "United Kingdom"),
        ("🇨🇦", "+1",   "Canada"),
        ("🇦🇺", "+61",  "Australia"),
        ("🇩🇪", "+49",  "Germany"),
        ("🇫🇷", "+33",  "France"),
        ("🇯🇵", "+81",  "Japan"),
        ("🇧🇷", "+55",  "Brazil"),
        ("🇮🇳", "+91",  "India"),
        ("🇳🇬", "+234", "Nigeria"),
        ("🇿🇦", "+27",  "South Africa"),
        ("🇰🇪", "+254", "Kenya"),
        ("🇲🇽", "+52",  "Mexico"),
        ("🇸🇬", "+65",  "Singapore"),
        ("🇦🇪", "+971", "UAE"),
    ]

    var body: some View {
        NavigationStack {
            List(countries, id: \.code) { country in
                Button {
                    selected = country.code
                    dismiss()
                } label: {
                    HStack {
                        Text(country.flag)
                        Text(country.name)
                        Spacer()
                        Text(country.code)
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundColor(.primary)
            }
            .navigationTitle("Country Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
