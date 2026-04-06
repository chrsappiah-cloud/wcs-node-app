import StoreKit
import SwiftUI

/// Subscription paywall sheet.
/// Shows free tier vs premium tier feature comparison with live StoreKit pricing.
struct SubscriptionPaywallView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var showError = false

    enum SubscriptionPlan: String, CaseIterable {
        case monthly = "Monthly"
        case yearly  = "Yearly"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .teal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 24)

                        Text("GeoWCS Premium")
                            .font(.title.bold())

                        Text("Unlock the full shared-location experience.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 28)

                    // Feature comparison
                    FeatureComparisonTable()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    // Plan toggle
                    PlanToggle(selected: $selectedPlan)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    // Price cards
                    HStack(spacing: 12) {
                        PlanCard(
                            plan: .monthly,
                            product: entitlementManager.monthlyProduct(),
                            isSelected: selectedPlan == .monthly
                        )
                        .onTapGesture { selectedPlan = .monthly }

                        PlanCard(
                            plan: .yearly,
                            product: entitlementManager.yearlyProduct(),
                            isSelected: selectedPlan == .yearly,
                            savingsBadge: savingsBadge()
                        )
                        .onTapGesture { selectedPlan = .yearly }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                    // CTA
                    Button {
                        Task { await purchase() }
                    } label: {
                        HStack {
                            if entitlementManager.purchaseInProgress {
                                ProgressView().tint(.white)
                            }
                            Text(ctaTitle)
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(entitlementManager.purchaseInProgress || selectedProduct() == nil)
                    .padding(.horizontal, 20)

                    // Restore
                    Button {
                        Task { await entitlementManager.restorePurchases() }
                    } label: {
                        Text(entitlementManager.restoreInProgress ? "Restoring…" : "Restore Purchases")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .disabled(entitlementManager.restoreInProgress)
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                    Text("Subscriptions auto-renew. Cancel anytime in Settings.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { dismiss() }
                }
            }
            .onChange(of: entitlementManager.isPremium) { _, premium in
                if premium { dismiss() }
            }
            .onChange(of: entitlementManager.lastError) { _, err in
                if err != nil { showError = true }
            }
            .alert("Purchase Error", isPresented: $showError, presenting: entitlementManager.lastError) { _ in
                Button("OK") { entitlementManager.lastError = nil }
            } message: { err in
                Text(err)
            }
        }
    }

    // MARK: - Private

    private func selectedProduct() -> Product? {
        switch selectedPlan {
        case .monthly: return entitlementManager.monthlyProduct()
        case .yearly:  return entitlementManager.yearlyProduct()
        }
    }

    private func purchase() async {
        guard let p = selectedProduct() else { return }
        await entitlementManager.purchase(p)
    }

    private var ctaTitle: String {
        guard let p = selectedProduct() else { return "Subscribe" }
        return "Subscribe for \(p.displayPrice)"
    }

    private func savingsBadge() -> String? {
        guard let monthly = entitlementManager.monthlyProduct(),
              let yearly  = entitlementManager.yearlyProduct(),
              let mPrice = monthly.subscription?.introductoryOffer?.price,
              let yPrice = yearly.subscription?.introductoryOffer?.price
        else {
            // Fallback: infer from display prices
            guard let mP = entitlementManager.monthlyProduct()?.price,
                  let yP = entitlementManager.yearlyProduct()?.price,
                  mP > 0
            else { return nil }
            let monthlyValue = NSDecimalNumber(decimal: mP).doubleValue
            let yearlyValue = NSDecimalNumber(decimal: yP).doubleValue
            guard monthlyValue > 0 else { return nil }
            let annualFromMonthly = monthlyValue * 12.0
            let pct = Int((((annualFromMonthly - yearlyValue) / annualFromMonthly) * 100.0).rounded())
            return pct > 0 ? "Save \(pct)%" : nil
        }
        let monthlyValue = NSDecimalNumber(decimal: mPrice).doubleValue
        let yearlyValue = NSDecimalNumber(decimal: yPrice).doubleValue
        guard monthlyValue > 0 else { return nil }
        let annualFromMonthly = monthlyValue * 12.0
        let pct = Int((((annualFromMonthly - yearlyValue) / annualFromMonthly) * 100.0).rounded())
        return pct > 0 ? "Save \(pct)%" : nil
    }
}

// MARK: - Feature comparison table

private struct FeatureComparisonTable: View {
    private let rows: [(feature: String, free: String, premium: String)] = [
        ("Circles",                  "2",         "Unlimited"),
        ("Live map",                 "✗",         "✓"),
        ("Location history",         "3 days",    "30 days"),
        ("Geofence alerts",          "✓",         "✓"),
        ("Background location",      "✓",         "✓"),
        ("Priority support",         "✗",         "✓"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Feature").font(.caption.bold()).foregroundStyle(.secondary)
                Spacer()
                Text("Free").font(.caption.bold()).foregroundStyle(.secondary).frame(width: 72, alignment: .center)
                Text("Premium").font(.caption.bold()).foregroundStyle(.blue).frame(width: 80, alignment: .center)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)

            Divider()

            ForEach(rows, id: \.feature) { row in
                HStack {
                    Text(row.feature).font(.subheadline)
                    Spacer()
                    Text(row.free)
                        .font(.subheadline)
                        .foregroundStyle(row.free == "✗" ? .tertiary : .primary)
                        .frame(width: 72, alignment: .center)
                    Text(row.premium)
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                        .frame(width: 80, alignment: .center)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)

                Divider()
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Plan toggle

private struct PlanToggle: View {
    @Binding var selected: SubscriptionPaywallView.SubscriptionPlan

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SubscriptionPaywallView.SubscriptionPlan.allCases, id: \.self) { plan in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selected = plan }
                } label: {
                    Text(plan.rawValue)
                        .font(.subheadline.weight(selected == plan ? .semibold : .regular))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(selected == plan ? Color.blue : Color.clear)
                        .foregroundColor(selected == plan ? .white : .secondary)
                        .cornerRadius(9)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Plan card

private struct PlanCard: View {
    let plan: SubscriptionPaywallView.SubscriptionPlan
    let product: Product?
    let isSelected: Bool
    var savingsBadge: String? = nil

    var body: some View {
        VStack(spacing: 6) {
            if let badge = savingsBadge {
                Text(badge)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }

            Text(plan.rawValue)
                .font(.subheadline.bold())

            if let p = product {
                Text(p.displayPrice)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                Text(plan == .yearly ? "/ year" : "/ month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
                    .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}
