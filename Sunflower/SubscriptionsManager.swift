import RevenueCat
import SwiftUI
import FacebookCore

enum PurchaseResult {
    case success
    case cancel
    case failure(String)
}

@MainActor
class SubscriptionsManager: NSObject, ObservableObject {
    @Published
    var offerings: Offerings? = nil

    let watchManager: WatchManager
    let userInfo: UserInfo

    @AppStorage(DefaultKeys.proType.rawValue, store: UserDefaults(suiteName: DefaultKeys.suite.rawValue))
    var proType: ProType = .freeTrial

    init(isPreview: Bool = false, watchManager: WatchManager, userInfo: UserInfo) {
        self.watchManager = watchManager
        self.userInfo = userInfo
        super.init()
        guard !isPreview else {
            return
        }
        Task {
            await getCustomerInfo()
            await fetchProducts()
        }
    }

    func getCustomerInfo() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()

            if !customerInfo.activeSubscriptions.isEmpty {
                print("SUBSCRIPTION FOUND")
                proType = .subscription
            } else if !customerInfo.nonSubscriptions.isEmpty {
                print("ALL TIME FOUND")
                proType = .allTime
            } else {
                if let onboardingDateValue = userInfo.onboardingDateValue, onboardingDateValue.daysSinceNow() ?? 0 > 3 {
                    proType = .none
                } else {
                    proType = .freeTrial
                }
            }
            print("pro type set: \(proType)")
            watchManager.sendIsPro(isPro: proType != .none)
        } catch {
            print(error)
        }
    }

    func fetchProducts() async {
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            print(error)
//            Logger.shared.logError(error)
        }
    }

    func buy(package: Package) async -> PurchaseResult {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            switch result {
            case (_, let customerInfo, let userCancelled):
                guard !userCancelled else {
                    return .cancel
                }

                AppEvents.shared.logEvent(AppEvents.Name("CompletePurchase"))
                if !customerInfo.activeSubscriptions.isEmpty {
                    proType = .subscription
                } else if !customerInfo.nonSubscriptions.isEmpty {
                    proType = .allTime
                }

                return .success
            }
        } catch {
            print(error)
            return .failure(error.localizedDescription)
        }
    }

    func restorePurchases() async {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            if customerInfo.activeSubscriptions.isEmpty {

            } else {

            }
        } catch {
            print(error)
        }
    }
}
