//
//  EntitlementManager.swift
//  GeoWCS - Subscription Entitlement Management
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//

import Combine
import StoreKit
import SwiftUI

/// StoreKit 2 entitlement manager.
/// Listens to Transaction.updates and verifies current entitlements on launch.
/// Keeps the bearer token's tier field in sync with StoreKit state.
@MainActor
final class EntitlementManager: ObservableObject {

    // MARK: Product IDs

    static let monthlyProductID = "com.geowcs.premium.monthly"
    static let yearlyProductID  = "com.geowcs.premium.yearly"
    static let allProductIDs    = [monthlyProductID, yearlyProductID]

    // MARK: Published

    @Published private(set) var isPremium: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseInProgress: Bool = false
    @Published private(set) var restoreInProgress: Bool = false
    @Published var lastError: String?

    // MARK: - Init + background listener

    private var updateTask: Task<Void, Never>?

    init() {
        updateTask = Task { [weak self] in
            await self?.listenForTransactionUpdates()
        }
        Task { await loadProducts() }
        Task { await refreshEntitlements() }
    }

    deinit {
        updateTask?.cancel()
    }

    // MARK: - StoreKit

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: Self.allProductIDs)
            products = loaded.sorted { p1, p2 in
                // Sort monthly before yearly for default display
                p1.id == Self.monthlyProductID
            }
        } catch {
            lastError = "Couldn't load subscription options: \(error.localizedDescription)"
        }
    }

    func purchase(_ product: Product) async {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .pending:
                break // awaiting parental approval, etc.
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = "Purchase failed: \(error.localizedDescription)"
        }
    }

    func restorePurchases() async {
        restoreInProgress = true
        defer { restoreInProgress = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastError = "Restore failed: \(error.localizedDescription)"
        }
    }

    func monthlyProduct() -> Product? {
        products.first { $0.id == Self.monthlyProductID }
    }

    func yearlyProduct() -> Product? {
        products.first { $0.id == Self.yearlyProductID }
    }

    // MARK: - Private

    private func refreshEntitlements() async {
        var premium = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               Self.allProductIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                premium = true
                break
            }
        }
        isPremium = premium
    }

    private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            await transaction.finish()
            await refreshEntitlements()
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified(_, let error): throw error
        }
    }
}
