import Foundation

class SunWorker: ObservableObject {
    let healthManager: HealthStoreManager

    init(healthManager: HealthStoreManager) {
        self.healthManager = healthManager
    }

    func getSunTime(for date: Date) async -> Double? {
        do {
            let time = try await healthManager.fetchStatisticQuerySum(for: .timeInDaylight, startDate: date.startOfDay, endDate: date.endOfDay, unit: .second())
            return time?.value
        } catch {
            return nil
        }
    }
}

