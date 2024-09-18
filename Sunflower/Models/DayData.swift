import Foundation
import SwiftData

@Model
final class DayData {
    @Attribute(.unique) let date: Date

    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
    }
}
