import Foundation
import WidgetKit
import SwiftUI
import UserNotifications

class BackgroundNotificationsWorker: ObservableObject {
    private let sunWorker: SunWorker
    private let sleepWorker: SleepWorker
    private let healthStoreManager: HealthStoreManager

    init(sunWorker: SunWorker, healthStoreManager: HealthStoreManager, sleepWorker: SleepWorker) {
        self.sunWorker = sunWorker
        self.sleepWorker = sleepWorker
        self.healthStoreManager = healthStoreManager
    }

    func subscribeToNotifications() {
        healthStoreManager.handleBackgroundDaylightData {completion in
            Task {
                await self.handleDaylightNotificationData()
                completion()
            }
        }

        healthStoreManager.handleBackgroundSleepData { completion in
            Task {
                await self.handleSleepNotification()
                completion()
            }
        }
    }

    private func handleSleepNotification() async {
        let lastNotificationDate = getLastSleepNotificationDate()
        let shouldSendSleepNotif = lastNotificationDate?.isSameDay(as: Date()) != true

        let lastSampleDate = await sleepWorker.lastSampleDate(for: Date())

        guard shouldSendSleepNotif && isLastSampleDateLaterThanFourAM(lastSampleDate: lastSampleDate) else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Good Morning! 🌻"
        content.body = "Morning sun is really important for a Healthy Sunflower 🌞"
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        setLastSleepNotificationDate(Date())
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("SEND REQUEST")
        } catch {
            Logger.shared.logError(error)
        }
    }

    private func isLastSampleDateLaterThanFourAM(lastSampleDate: Date?) -> Bool {
        guard let lastSampleDate else {
            return false
        }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        var components = DateComponents()
        components.hour = 4
        components.minute = 0

        guard let fourAMDate = calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: startOfDay) else {
            return false
        }

        return lastSampleDate > fourAMDate
    }

    private func handleDaylightNotificationData() async {
        let timeInSun = await sunWorker.getSunTime(for: Date()) ?? 0
        storeAndRestoreWidget(timeInSun: timeInSun)
        sendNotification(timeInSun: timeInSun)
    }

    private func storeAndRestoreWidget(timeInSun: Double) {
        setTimeInSun(timeInSun)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func sendNotification(timeInSun: Double) {
        let lastPickedDate = getLastPickedDate()
        let wasPickedToday = lastPickedDate?.isSameDay(as: Date()) == true

        let lastNotificationDate = getLastSunNotificationDate()
        let fourHoursInSeconds: TimeInterval = 4 * 60 * 60
        let shouldSendAnotherNotification = lastNotificationDate == nil || Date().timeIntervalSince(lastNotificationDate!) > fourHoursInSeconds

        let sunGoal = getSunGoal()

        if timeInSun > sunGoal && !wasPickedToday && shouldSendAnotherNotification {
            let content = UNMutableNotificationContent()
            content.title = "🌻 Sunflower has grown!"
            content.body = "Don't forget to pick it!"
            content.sound = UNNotificationSound.default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            setLastSunNotificationDate(Date())

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    Logger.shared.logError(error)
                }
            }
        }
    }

    // MARK: - UserDefaults Helper Methods

    private func getLastSleepNotificationDate() -> Date? {
        UserDefaults(suiteName: DefaultKeys.suite.rawValue)?.object(forKey: DefaultKeys.lastSleepNotificationDate.rawValue) as? Date
    }

    private func setLastSleepNotificationDate(_ date: Date) {
        UserDefaults(suiteName: DefaultKeys.suite.rawValue)?.set(date, forKey: DefaultKeys.lastSleepNotificationDate.rawValue)
    }

    private func getLastPickedDate() -> Date? {
        UserDefaults(suiteName: DefaultKeys.suite.rawValue)?.object(forKey: DefaultKeys.lastPickedDate.rawValue) as? Date
    }

    private func getLastSunNotificationDate() -> Date? {
        UserDefaults(suiteName: DefaultKeys.suite.rawValue)?.object(forKey: DefaultKeys.lastSunNotificationDate.rawValue) as? Date
    }

    private func setLastSunNotificationDate(_ date: Date) {
        UserDefaults(suiteName: DefaultKeys.suite.rawValue)?.set(date, forKey: DefaultKeys.lastSunNotificationDate.rawValue)
    }

    private func getSunGoal() -> Double {
        UserDefaults(suiteName: DefaultKeys.suite.rawValue)?.double(forKey: DefaultKeys.sunGoal.rawValue) ?? 30 * 60
    }

    private func setTimeInSun(_ time: Double) {
        UserDefaults(suiteName: DefaultKeys.suite.rawValue)?.set(time, forKey: DefaultKeys.timeInSun.rawValue)
    }
}
