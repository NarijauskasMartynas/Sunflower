import Foundation
import WidgetKit

class WatchBackgroundNotificationsWorker: NSObject, ObservableObject {
    private let sunWorker: SunWorker
    private let healthWorker: HealthStoreManager

    init(sunWorker: SunWorker, healthWorker: HealthStoreManager) {
        self.sunWorker = sunWorker
        self.healthWorker = healthWorker
        super.init()
    }

    func subscribeToNotification() {
        healthWorker.handleBackgroundDaylightData { [weak self] completion in
            Task { [weak self] in
                await self?.handleSunNotification()
                completion()
            }
        }
    }

    func handlePeriodicUpdate() async {
        await handleSunNotification()
    }

    private func handleSunNotification() async {
        let timeInSun = await sunWorker.getSunTime(for: Date())
        UserDefaults(suiteName: WatchDefaultKeys.suite.rawValue)?.setValue(timeInSun, forKey: WatchDefaultKeys.timeInSun.rawValue)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
