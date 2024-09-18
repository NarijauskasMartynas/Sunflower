import SwiftUI

struct CalendarDay: Identifiable {
    let id = UUID()
    let day: CalendarModel?
}

struct CalendarModel {
    let date: Date
    let isPicked: Bool
    let isFuture: Bool
    let isToday: Bool
    let goalAchieved: Bool
    let timeInMinutes: Double
}

enum SunflowerState {
    case picked
    case notEnoughSun
    case notPickedButEnoughSun
    case future

    var text: String {
        switch self {
        case .notEnoughSun:
            return "☁️"
        case .notPickedButEnoughSun:
            return "🌞"
        case .picked:
            return "🌻"
        case .future:
            return ""
        }
    }

    var backgroundColor: Color {
        switch self {
        case .notEnoughSun:
            return AppColors.red.color
        case .notPickedButEnoughSun:
            return AppColors.white.color
        case .picked:
            return AppColors.blue.color
        case .future:
            return .clear
        }
    }
}

struct DayView: View {
    let day: CalendarModel

    var state: SunflowerState {
        guard !day.isFuture else {
            return .future
        }
        if day.isPicked {
            return .picked
        } else if day.goalAchieved {
            return .notPickedButEnoughSun
        } else {
            return .notEnoughSun
        }
    }

    var body: some View {
        VStack {
            if day.isFuture {
                Spacer()
                HStack {
                    Text(day.date.dayString())
                        .font(.body)
                        .foregroundStyle(AppColors.green.color)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
                Spacer()
            } else {
                HStack {
                    Spacer()
                    Text(day.date.dayString())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.green.color)
                        .lineLimit(1)
                }
                ZStack {
                    Text(state.text)
                        .font(.system(size: 30))
                        .opacity(0.25)


                    Text(day.timeInMinutes.hoursMinutesVertical())
                        .font(.system(size: 13))
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.green.color)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(height: 60)
        .padding(5)
        .background(state.backgroundColor)
        .cornerRadius(2)
    }
}

#Preview {
    DayView(day: .init(date: Date(), isPicked: true, isFuture: false, isToday: false, goalAchieved: true, timeInMinutes: 20000))
        .frame(width: 100)
}
