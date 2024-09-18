//
//  watchkitappApp.swift
//  watchkitapp Watch App
//
//  Created by Martynas Narijauskas on 29/08/2024.
//

import SwiftUI
import WatchConnectivity
import WidgetKit

@main
struct watchkitapp_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(ExtensionDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .ignoresSafeArea(.all)
                    .background(AppColors.backgroundLight.color)
                    .environmentObject(delegate.watchUserInfo)
                    .environmentObject(delegate.sunWorker!)
                    .environmentObject(delegate.healthStoreManager!)
                    .environmentObject(delegate.watchToAppManager)
            }.background(AppColors.backgroundLight.color)
                .ignoresSafeArea(.all)
        }
    }
}

class ExtensionDelegate: NSObject, WKApplicationDelegate, WCSessionDelegate {
    let session = WCSession.default
    let watchUserInfo = WatchUserInfo()
    var healthStoreManager: HealthStoreManager?
    var sunWorker: SunWorker?
    let watchToAppManager = WatchToAppManager()
    var watchBackgroundNotificationsWorker: WatchBackgroundNotificationsWorker?

    override init() {
        super.init()
        initializeWorkersIfNeeded()
    }

    func applicationDidFinishLaunching() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
        scheduleNextBackgroundRefresh()
    }

    private func initializeWorkersIfNeeded() {
        healthStoreManager = HealthStoreManager()

        guard let healthStoreManager = healthStoreManager else {
            print("Failed to initialize HealthStoreManager")
            return
        }

        sunWorker = SunWorker(healthManager: healthStoreManager)

        guard let sunWorker = sunWorker else {
            print("Failed to initialize SunWorker")
            return
        }

        watchBackgroundNotificationsWorker = WatchBackgroundNotificationsWorker(sunWorker: sunWorker, healthWorker: healthStoreManager)
        watchBackgroundNotificationsWorker?.subscribeToNotification()
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                handleBackgroundRefresh(task: backgroundTask)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    private func handleBackgroundRefresh(task: WKApplicationRefreshBackgroundTask) {
        Task {
            await watchBackgroundNotificationsWorker?.handlePeriodicUpdate()
            scheduleNextBackgroundRefresh()
            task.setTaskCompletedWithSnapshot(false)
        }
    }

    private func scheduleNextBackgroundRefresh() {
        let now = Date()
        let calendar = Calendar.current

        var nextRefreshDate = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: now) ?? now

        if nextRefreshDate <= now {
//            nextRefreshDate = calendar.date(byAdding: .minute, value: 30, to: now) ?? now
            nextRefreshDate = calendar.date(byAdding: .minute, value: 30, to: now) ?? now
        }

        // Ensure the next refresh is not after midnight
        let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 1, to: now) ?? now) ?? now
        if nextRefreshDate > midnight {
            nextRefreshDate = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: midnight) ?? midnight
        }

        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: nextRefreshDate, userInfo: nil) { error in
            if let error = error {
                print("Failed to schedule background refresh: \(error.localizedDescription)")
            } else {
                print("Background refresh scheduled for: \(nextRefreshDate)")
            }
        }
    }

    // WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Session activation failed with error: \(error.localizedDescription)")
        } else {
            print("Session activated with state: \(activationState.rawValue)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        print("Message received:")
        print(userInfo)
        DispatchQueue.main.async { [weak self] in
            if let isPro = userInfo["isPro"] as? NSNumber {
                self?.watchUserInfo.isPro = isPro.boolValue
            } else if let sunGoal = userInfo["sunGoal"] as? NSNumber {
                self?.watchUserInfo.sunGoal = sunGoal.doubleValue
            } else if let timeInSun = userInfo["timeInSun"] as? NSNumber {
                self?.watchUserInfo.timeInSun = timeInSun.doubleValue
            } else if let lastPickedSunflowerDate = userInfo["lastSunflowerDate"] as? String {
                self?.watchUserInfo.lastPickedSunflowerDateString = lastPickedSunflowerDate
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}


class WatchUserInfo: ObservableObject {
    @AppStorage(WatchDefaultKeys.sunGoal.rawValue, store: UserDefaults(suiteName: WatchDefaultKeys.suite.rawValue))
    var sunGoal: Double = 30 * 60

    @AppStorage(WatchDefaultKeys.isPro.rawValue, store: UserDefaults(suiteName: WatchDefaultKeys.suite.rawValue))
    var isPro: Bool = false

    @AppStorage(WatchDefaultKeys.timeInSun.rawValue, store: UserDefaults(suiteName: WatchDefaultKeys.suite.rawValue))
    var timeInSun: Double = 0

    @AppStorage(WatchDefaultKeys.lastPickedSunflowerDate.rawValue, store: UserDefaults(suiteName: WatchDefaultKeys.suite.rawValue))
    var lastPickedSunflowerDateString: String?

    var lastPickedSunflowerDate: Date? {
        get {
            // Convert stored String to Date
            guard let dateString = lastPickedSunflowerDateString else { return nil }
            let dateFormatter = ISO8601DateFormatter()
            return dateFormatter.date(from: dateString)
        }
        set {
            if let date = newValue {
                lastPickedSunflowerDateString = date.iso8601String
            } else {
                lastPickedSunflowerDateString = nil
            }
        }
    }
}

struct SunGoalContainer: Codable {
    var timeInSun: Double
    var date: Date
}

extension SunGoalContainer {
    var dictionary: [String: Any]? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self),
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let dictionary = json as? [String: Any] else {
            return nil
        }
        return dictionary
    }

    var encodedData: Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
}
