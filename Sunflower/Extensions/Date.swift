import Foundation

extension Date {
    var startOfDay: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: self)
        components.hour = 0
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? self
    }

    var endOfDay: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        components.hour = 23
        components.minute = 59
        components.second = 59
        return calendar.date(from: components) ?? self
    }

    func dayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }

    func isSameMonth(as otherDate: Date) -> Bool {
        let calendar = Calendar.current
        let selfComponents = calendar.dateComponents([.year, .month], from: self)
        let otherComponents = calendar.dateComponents([.year, .month], from: otherDate)

        return selfComponents.year == otherComponents.year && selfComponents.month == otherComponents.month
    }

    func isSameDay(as otherDate: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, inSameDayAs: otherDate)
    }

    var iso8601String: String {
        return ISO8601DateFormatter().string(from: self)
    }

    static func fromISO8601String(_ string: String) -> Date? {
        return ISO8601DateFormatter().date(from: string)
    }

    func daysSinceNow() -> Int? {
        let calendar = Calendar.current

        let startOfDaySelf = calendar.startOfDay(for: self)
        let startOfDayNow = calendar.startOfDay(for: Date())

        let components = calendar.dateComponents([.day], from: startOfDaySelf, to: startOfDayNow)
        return components.day
    }

    func getTodayDatesAt15() -> (today: Date, yesterday: Date) {
        var calendar = Calendar.current
        calendar.timeZone = .current

        // Hardcoding 15:00
        let yesterdayAt15 = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: -1, to: self)!)!
        let todayAt15 = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: self)!
        return (todayAt15, yesterdayAt15)
    }
}
