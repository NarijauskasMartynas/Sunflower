import SwiftUI
import HealthKit

struct HealthDataPoint: Codable {
    let value: Double
    let startDate: Date
    let endDate: Date
}

enum HealthKitCompletion {
    case failure
    case success
}

class HealthStoreManager: ObservableObject {
    private let healthStore = HKHealthStore()

    let sampleTypesToRead = Set([
        HKObjectType.quantityType(forIdentifier: .timeInDaylight)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
    ])

    func checkHealthKitPermissionsStatus() async -> HKAuthorizationRequestStatus {
        do {
            let status = try await healthStore.statusForAuthorizationRequest(toShare: [], read: self.sampleTypesToRead)
            return status
        } catch {
            print("Error checking health kit permissions status: \(error)")
            return .unknown
        }
    }

    func requestHealthKitPermissions() async -> HealthKitCompletion {
        do {
            _ = try await healthStore.requestAuthorization(toShare: [], read: self.sampleTypesToRead)
            return .success
        } catch {
            return .failure
        }
    }

    func fetchStatisticQuerySum(for identifier: HKQuantityTypeIdentifier, startDate: Date, endDate: Date, unit: HKUnit) async throws -> HealthDataPoint? {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                guard let result = result, error == nil else {
                    continuation.resume(returning: nil)
                    return
                }

                let returnedValue = result.sumQuantity()?.doubleValue(for: unit)
                guard let returnedValue else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: .init(value: returnedValue, startDate: result.startDate, endDate: result.endDate))
            }

            healthStore.execute(query)
        }
    }

    func getIsSleepDataValid(date: Date) async throws -> Date? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let (todayAt15, yesterdayAt15) = date.getTodayDatesAt15()

        print("Querying for sleep data from \(todayAt15) to \(yesterdayAt15)")

        let predicate = HKQuery.predicateForSamples(withStart: yesterdayAt15, end: todayAt15, options: .strictEndDate)

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }

                if let error = error {
                    print("Query error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let samples = samples as? [HKCategorySample] else {
                    print("No samples returned")
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: samples.last?.endDate)
            }

            self?.healthStore.execute(query)
        }
    }

    func handleBackgroundDaylightData(completion: @escaping (_ onComplete: @escaping () -> Void) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .timeInDaylight)!

        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate, withCompletion: { succeed, error in
            if let error = error {
                print("Error")
            }
        })

        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { query, completionHandler, error in
            if let error = error {
                print("ERROR")
                return
            }

            completion {
                completionHandler()
            }
        }

        healthStore.execute(query)
    }

    func handleBackgroundSleepData(completion: @escaping (_ onComplete: @escaping () -> Void) -> Void) {
        guard let stepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return
        }

        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate, withCompletion: { succeed, error in
            if let error = error {
                print("Error")
            }
        })

        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { query, completionHandler, error in
            if let error = error {
                print("ERROR")
                return
            }

            completion {
                completionHandler()
            }
        }

        healthStore.execute(query)
    }


}
