import WidgetKit
import SwiftUI
import AppIntents
import SwiftData

struct SunEntryProvider: TimelineProvider {
    func placeholder(in context: Context) -> SunEntry {
        SunEntry(timeInSun: 981, sunGoal: 1000, isPro: true, date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SunEntry) -> ()) {
        let entry = SunEntry(timeInSun: 981, sunGoal: 1000, isPro: true, date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SunEntry] = []
        let userDefaults = UserDefaults(suiteName: DefaultKeys.suite.rawValue)!
        let timeInSun = userDefaults.double(forKey: DefaultKeys.timeInSun.rawValue)
        let sunGoal = userDefaults.double(forKey: DefaultKeys.sunGoal.rawValue)
        let isPro = userDefaults.string(forKey: DefaultKeys.proType.rawValue)
        let proType = ProType(rawValue: isPro ?? "none") ?? .none

        let currentDate = Date()
        let calendar = Calendar.current

        // Check if it's after midnight
        if calendar.component(.hour, from: currentDate) >= 0 && calendar.component(.hour, from: currentDate) < 6 {
            // If it's after midnight but before 6 AM, schedule for 6 AM
            var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
            components.hour = 6
            components.minute = 0
            components.second = 0
            if let nextUpdate = calendar.date(from: components) {
                entries.append(.init(timeInSun: timeInSun, sunGoal: sunGoal, isPro: proType != .none, date: nextUpdate))
            }
        } else {
            // Schedule every 30 minutes from now
            let thirtyMinutesFromNow = currentDate.addingTimeInterval(30 * 60)
            entries.append(.init(timeInSun: timeInSun, sunGoal: sunGoal, isPro: proType != .none, date: thirtyMinutesFromNow))
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SunEntry: TimelineEntry {
    let timeInSun: Double
    let sunGoal: Double
    let isPro: Bool
    let date: Date
}

struct SunWidgetEntryView : View {
    var entry: SunEntryProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryInline:
            if entry.isPro {
                Text("🌻 Time in Sun: \(entry.timeInSun.hoursMinutes())")
                    .font(.system(size: 14, weight: .semibold))
                    .widgetAccentable()
            } else {
                Text("🌻 Get Sunflower+")
                    .font(.system(size: 14, weight: .semibold))
                    .widgetAccentable()
            }
        case .accessoryCircular:
            if entry.isPro {
                Gauge(
                    value: entry.sunGoal > entry.timeInSun ? entry.timeInSun : entry.sunGoal,
                    in: 0...entry.sunGoal,
                    label: {},
                    currentValueLabel: {
                        Text(entry.timeInSun.hoursMinutes())
                            .font(.system(size: 14, weight: .semibold))
                            .widgetAccentable()
                            .lineLimit(1)
                    },
                    minimumValueLabel: { Text("0") },
                    maximumValueLabel: { Text("\(entry.sunGoal.onlyMinutes())") }
                )
                .gaugeStyle(.accessoryCircular)
                .overlay(
                    Text("🌻")
                        .font(.system(size: 40))
                        .opacity(0.3)
                )
            } else {
                VStack {
                    Image(systemName: "lock")
                    Text("Sunflower+")
                        .font(.caption)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
        case .accessoryRectangular:
            if entry.isPro {
                HStack {
                    Text("🌻")
                        .font(.system(size: 40))
                    Gauge(
                        value: entry.sunGoal > entry.timeInSun ? entry.timeInSun : entry.sunGoal,
                        in: 0...entry.sunGoal,
                        label: {},
                        currentValueLabel: {
                            Text(entry.timeInSun.hoursMinutes())
                                .font(.system(size: 14, weight: .semibold))
                                .widgetAccentable()
                        },
                        minimumValueLabel: { Text("0") },
                        maximumValueLabel: { Text("\(entry.sunGoal.onlyMinutes())") }
                    )
                    .gaugeStyle(.accessoryCircular)
                }
            } else {
                VStack {
                    Text("Get Sunflower+ to see the widgets")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.green.color)
                }
            }
        case .systemMedium:
            if entry.isPro {
                HStack(spacing: 5) {
                    Text("🌻")
                        .font(.system(size: 60))
                    VStack {
                        HStack() {
                            Text("Time In Sun")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.green.color.opacity(0.7))
                            Spacer()
                            Text(entry.timeInSun.hoursMinutes())
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.green.color)
                        }
                        .padding(5)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(10)

                        HStack() {
                            Text("Sun Goal")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.green.color.opacity(0.7))
                            Spacer()
                            Text(entry.sunGoal.hoursMinutes())
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.green.color)
                        }
                        .padding(5)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(10)
                    }
                }
            } else {
                VStack {
                    Text("Get Sunflower+ to see the widgets")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.green.color)
                        .padding()
                }
            }
        case .systemSmall:
            if entry.isPro {
                VStack(spacing: 5) {
                    Spacer()
                    HStack {
                        Text("🌻")
                            .font(.system(size: 30))
                        
                        VStack(spacing: 0) {
                            Text("Time In Sun")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.green.color.opacity(0.7))
                            
                            Text(entry.timeInSun.hoursMinutes())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.green.color)
                        }
                        .padding(2)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(10)
                    }
                    Spacer()
                }
            } else {
                VStack {
                    Text("Get Sunflower+ to see the widgets")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.green.color)
                        .padding()
                }
            }
        default:
            Text("Hey")
        }
    }
}

struct AppWidget: Widget {
    let kind: String = "TimeInSunWidget"
    let gradient = LinearGradient(gradient: Gradient(colors: [AppColors.orange.color.opacity(0.6), AppColors.backgroundLight.color.opacity(0.4)]),
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing)
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SunEntryProvider()) { entry in
            if #available(iOS 17.0, *) {
                SunWidgetEntryView(entry: entry)
                    .containerBackground(gradient, for: .widget)
            } else {
                SunWidgetEntryView(entry: entry)
                    .padding()
                    .background(gradient)
            }
        }
        .configurationDisplayName("Time in Sun Widget")
        .description("Widget that shows your time in sun")
        .supportedFamilies(
            [.systemSmall,
             .accessoryInline,
             .accessoryCircular,
             .accessoryRectangular,
             .systemMedium,
             .systemSmall
            ]
        )
    }
}

#Preview(as: .accessoryInline) {
    AppWidget()
} timeline: {
    SunEntry(timeInSun: 999, sunGoal: 1500, isPro: true, date: Date())
    SunEntry(timeInSun: 15000, sunGoal: 1500, isPro: false, date: Date())
}

class UserDefaultsDateHelper {
    static let shared = UserDefaultsDateHelper()

    private let userDefaults: UserDefaults

    private init() {
        self.userDefaults = UserDefaults(suiteName: DefaultKeys.suite.rawValue)!
    }

    var lastPickedDate: Date? {
        get {
            if let dateString = userDefaults.string(forKey: DefaultKeys.lastPickedDate.rawValue) {
                return Date.fromISO8601String(dateString)
            }
            return nil
        }
        set {
            if let date = newValue {
                userDefaults.set(date.iso8601String, forKey: DefaultKeys.lastPickedDate.rawValue)
            } else {
                userDefaults.removeObject(forKey: DefaultKeys.lastPickedDate.rawValue)
            }
        }
    }
}
