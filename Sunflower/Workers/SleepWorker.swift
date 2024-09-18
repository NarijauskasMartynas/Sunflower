import Foundation

class SleepWorker: ObservableObject {
    let healthManager: HealthStoreManager

    init(healthManager: HealthStoreManager) {
        self.healthManager = healthManager
    }

    func lastSampleDate(for date: Date) async -> Date? {
        do {
            let time = try await healthManager.getIsSleepDataValid(date: Date())
            return time
        } catch {
            print(error)
            return nil
        }
    }
}
