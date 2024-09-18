import SwiftUI
import SwiftData
import RevenueCat

class AppState: ObservableObject {
    @Published
    var showLoader = false

    @AppStorage(DefaultKeys.seenOnboarding.rawValue, store: UserDefaults(suiteName: DefaultKeys.suite.rawValue))
    var seenOnboarding: Bool = false

    init(showLoader: Bool = false) {
        self.showLoader = showLoader
    }
}

@main
struct SunflowerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        delegate.watchManager?.userInfo = delegate.userInfo
        return WindowGroup {
            MainContentView()
                .environmentObject(delegate.userInfo!)
                .environmentObject(delegate.healthStoreManager!)
                .environmentObject(delegate.sunWorker!)
                .environmentObject(delegate.sleepWorker!)
                .environmentObject(delegate.appState!)
                .environmentObject(delegate.subscriptionsManager!)
                .environmentObject(delegate.watchManager!)
                .environmentObject(delegate.backgroundNotificationsWorker!)
        }.modelContainer(delegate.modelContainer!)
    }
}

struct MainContentView: View {
    @EnvironmentObject var userInfo: UserInfo
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var watchManager: WatchManager
    @EnvironmentObject var subscriptionsManager: SubscriptionsManager
    @Environment(\.modelContext) private var modelContext

    var body: some View {
            ZStack {
                if appState.seenOnboarding == false {
                    OnboardingScroller() {
                        appState.seenOnboarding = true
                    }
                } else {
                    if let onboardingDate = userInfo.onboardingDateValue,
                       onboardingDate.daysSinceNow() ?? 0 > 3 &&
                        subscriptionsManager.proType == .none {
                        SubscriptionView(isFirst: false, isForce: true, onClose: {})
                            .onAppear {
                                if userInfo.promoOfferStartDateValue == nil {
                                    userInfo.promoOfferStartDateValue = Date()
                                }
                            }
                    } else {
                        SunflowerTab()
                    }
                }
            }.overlay (
                appState.showLoader ? GlobalLoaderOverlay() : nil
            )
    }

}
