import WidgetKit
import SwiftUI

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
        let userDefaults = UserDefaults(suiteName: WatchDefaultKeys.suite.rawValue)!
        let timeInSun = userDefaults.double(forKey: WatchDefaultKeys.timeInSun.rawValue)
        let sunGoal = userDefaults.double(forKey: WatchDefaultKeys.sunGoal.rawValue)
        let isPro = userDefaults.bool(forKey: WatchDefaultKeys.isPro.rawValue)

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
                entries.append(.init(timeInSun: timeInSun, sunGoal: sunGoal, isPro: isPro, date: nextUpdate))
            }
        } else {
            // Schedule every 30 minutes from now
            let thirtyMinutesFromNow = currentDate.addingTimeInterval(30 * 60)
            entries.append(.init(timeInSun: timeInSun, sunGoal: sunGoal, isPro: isPro, date: thirtyMinutesFromNow))
        }

        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
}

struct SunEntry: TimelineEntry {
    let timeInSun: Double
    let sunGoal: Double
    let isPro: Bool
    let date: Date
}


struct SunEntryView : View {
    var entry: SunEntryProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            if entry.isPro {
                ZStack {
                    Text("🌻")
                        .font(.system(size: 40))
                        .opacity(0.3)

                    Text(entry.timeInSun.hoursMinutes())
                        .font(.system(size: 14, weight: .bold))
                        .widgetAccentable()
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack {
                    Image(systemName: "lock")
                    Text("🌻+")
                        .font(.caption)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
        case .accessoryInline:
            if entry.isPro {
                Text("\(entry.timeInSun.hoursMinutes()) 🌻")
            } else {
                Text("🌻 Get Sunflower+")
            }
        case .accessoryCorner:
            if entry.isPro {
                VStack {
                    Text("\(entry.timeInSun.hoursMinutes()) 🌻")
                }
                .widgetCurvesContent()
                .widgetLabel {
                    Gauge(
                        value: entry.sunGoal > entry.timeInSun ? entry.timeInSun : entry.sunGoal,
                        in: 0...entry.sunGoal
                    ) {

                    } currentValueLabel: {
                        Text("20")
                    } minimumValueLabel: {
                        Text("0")
                            .foregroundStyle(AppColors.orange.color)
                    } maximumValueLabel: {
                        Text("\(entry.sunGoal.hoursMinutes())")
                            .foregroundStyle(AppColors.green.color)
                    }
                }
            } else {
                VStack {
                    Text("🌻+")
                }
                .widgetCurvesContent()
            }

        case .accessoryRectangular:
            if entry.isPro {
                HStack {
                    Text("🌻")
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Time in SUN:")
                                .font(.footnote)
                            Spacer()
                            Text(entry.timeInSun.hoursMinutes())
                                .font(.body)
                                .fontWeight(.bold)
                        }
                        HStack {
                            Text("Daily goal:")
                                .font(.footnote)
                            Spacer()
                            Text(entry.sunGoal.hoursMinutes())
                                .font(.body)
                                .fontWeight(.bold)
                        }
                    }
                }
            } else {
                VStack {
                    Text("Get Sunflower+ to see the complications")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.green.color)
                }
            }
        @unknown default:
            VStack {
                Text("Hey there ")
            }
        }
    }
}

@main
struct Complications: Widget {
    let kind: String = "Complications"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SunEntryProvider()) { entry in
            if #available(watchOS 10.0, *) {
                SunEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                SunEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Time in Sun")
        .description("Widget that shows how much time you spent in sun")
    }
}
