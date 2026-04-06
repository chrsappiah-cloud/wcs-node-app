import SwiftUI
import UIKit

struct AuthDiagnosticsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var showCopiedBanner = false
    @State private var isShowingShareSheet = false
    @State private var shareText = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Provider Diagnostics") {
                    ForEach(authManager.diagnostics()) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: item.status == .ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(item.status == .ok ? .green : .orange)
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                Text(item.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("How To Fix") {
                    Text("See AUTH_PROVIDER_SETUP.md for required Info.plist keys, URL schemes, backend endpoints, and provider setup steps.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Auth Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Copy") {
                        let report = buildDiagnosticsReport(from: authManager.diagnostics())
                        UIPasteboard.general.string = report
                        showCopiedBanner = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Share") {
                        shareText = buildDiagnosticsReport(from: authManager.diagnostics())
                        isShowingShareSheet = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Refresh") {
                        authManager.refreshConfigurationWarnings()
                    }
                }
            }
            .onAppear {
                authManager.refreshConfigurationWarnings()
            }
            .alert("Copied", isPresented: $showCopiedBanner) {
                Button("OK") {}
            } message: {
                Text("Auth diagnostics report copied to clipboard.")
            }
            .sheet(isPresented: $isShowingShareSheet) {
                ShareSheet(items: [shareText])
            }
        }
    }

    private func buildDiagnosticsReport(from items: [AuthDiagnosticItem]) -> String {
        let header = "GeoWCS Auth Diagnostics Report\nGenerated: \(Date())\n"
        let body = items.map { item in
            let status = item.status == .ok ? "OK" : "WARN"
            return "[\(status)] \(item.title): \(item.detail)"
        }.joined(separator: "\n")
        return "\(header)\n\(body)"
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
