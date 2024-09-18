import SwiftUI
import SwiftData

@propertyWrapper
@MainActor
struct FetchTodayData: DynamicProperty {
    @Query private var results: [DayData]

    init() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Safely calculate tomorrow's start date
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date().addingTimeInterval(86400)

        // Define predicate to fetch data between today and tomorrow
        let predicate = #Predicate<DayData> { dayData in
            dayData.date >= today && dayData.date < tomorrow
        }

        _results = Query(filter: predicate)
    }

    /// Returns the first result for today's data, if available
    var wrappedValue: DayData? {
        results.first
    }
}

@propertyWrapper
@MainActor
struct FetchStreakData: DynamicProperty {
    @Query private var results: [DayData]

    init() {
        // Fetch all DayData entries sorted by date
        _results = Query(sort: \.date, order: .forward)
    }

    /// Returns the streaks for today and yesterday
    var wrappedValue: (todayStreak: Int, yesterdayStreak: Int) {
        calculateStreak(from: results)
    }

    /// Function to calculate today's and yesterday's streak from the sorted results
    private func calculateStreak(from entries: [DayData]) -> (todayStreak: Int, yesterdayStreak: Int) {
        var todayStreak = 0
        var yesterdayStreak = 0
        var streak = 0
        var previousDate: Date?

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        for entry in entries {
            if let previous = previousDate {
                // Calculate the difference in days between the current and previous date
                let difference = calendar.dateComponents([.day], from: previous, to: entry.date).day ?? 0

                if difference == 1 {
                    // Increment the streak if the difference is exactly 1 day
                    streak += 1
                } else if difference > 1 {
                    // Break the streak if the difference is more than 1 day
                    streak = 1 // Reset streak for new consecutive days
                }
            } else {
                // First day starts the streak
                streak = 1
            }

            // Update the previousDate to the current date
            previousDate = entry.date

            // Update yesterday's streak
            if calendar.isDate(entry.date, inSameDayAs: yesterday) {
                yesterdayStreak = streak
            }

            // Update today's streak
            if calendar.isDateInToday(entry.date) {
                todayStreak = streak
            }
        }

        // If the last entry was yesterday, carry forward the streak to today
        if yesterdayStreak > 0 && !calendar.isDateInToday(previousDate!) {
            todayStreak = yesterdayStreak
        }

        return (todayStreak, yesterdayStreak)
    }
}
