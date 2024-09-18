import Foundation
import SwiftData
import FacebookCore
import FirebaseCore
//import AppTrackingTransparency
import FirebaseAnalytics
import SwiftUI
import RevenueCat

class AppDelegate: NSObject, UIApplicationDelegate {
    var subscriptionsManager: SubscriptionsManager?
    var healthStoreManager: HealthStoreManager?
    var watchManager: WatchManager?
    var sunWorker: SunWorker?
    var sleepWorker: SleepWorker?
    var userInfo: UserInfo?
    var appState: AppState?
    var backgroundNotificationsWorker: BackgroundNotificationsWorker?
    var modelContainer: ModelContainer?

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }

        ApplicationDelegate.shared.application(
            UIApplication.shared,
            open: url,
            sourceApplication: nil,
            annotation: [UIApplication.OpenURLOptionsKey.annotation]
        )
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        Purchases
            .configure(with: Configuration.Builder(withAPIKey: "appl_kltKSfYxolSrLFWjCgZlDNfaUjv")
                .with(storeKitVersion: .storeKit2)
                .build()
            )
        Purchases.logLevel = .debug

        Purchases.shared.delegate = self // make sure to set this after calling configure
        Purchases.shared.attribution.collectDeviceIdentifiers()
        Purchases.shared.attribution.setFBAnonymousID(FBSDKCoreKit.AppEvents.shared.anonymousID)

        FBSDKCoreKit.Settings.shared.isAutoLogAppEventsEnabled = true

        let instanceID = Analytics.appInstanceID()
        if let unwrapped = instanceID {
            Purchases.shared.attribution.setFirebaseAppInstanceID(unwrapped)
        }
        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()

        do {
            modelContainer = try ModelContainer(for: DayData.self)
        } catch {
            Logger.shared.logError(NSError(domain: "Model container not init", code: 133))
        }
        // SETUP HELPERS
        let userInfoTemp = UserInfo()
        guard let modelContainer else {
            return true
        }
        userInfo = userInfoTemp
        userInfo?.launchCount += 1
        watchManager = WatchManager(modelContainer: modelContainer)
        subscriptionsManager = SubscriptionsManager(watchManager: watchManager!, userInfo: userInfo!)
        healthStoreManager = HealthStoreManager()
        sunWorker = SunWorker(healthManager: healthStoreManager!)

        sleepWorker = SleepWorker(healthManager: healthStoreManager!)
        let backgroundNotifWorker = BackgroundNotificationsWorker(
            sunWorker: sunWorker!,
            healthStoreManager: healthStoreManager!,
            sleepWorker: sleepWorker!
        )
        appState = AppState()
        backgroundNotificationsWorker = backgroundNotifWorker
        return true
    }

    // Handle the notification response
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        userInfo?.lastSunNotificationDate = Date()

        completionHandler()
    }
}

extension AppDelegate: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task {
            await subscriptionsManager?.getCustomerInfo()
        }
    }
}
