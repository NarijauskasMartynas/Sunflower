import SwiftUI
import SwiftData

struct CalendarView: View {

    @EnvironmentObject
    var sunWorker: SunWorker

    @EnvironmentObject
    var userInfo: UserInfo

    @FetchStreakData
    private var streakCount

    @Environment(\.modelContext) private var modelContext

    @State private var currentMonth: Date = Date()
    @State private var calendarData: [CalendarModel] = []
    @State private var amountOfSunflowers: Int = 0

    @State private var selection = 1
    @State var numberOfPages: Int = 2
    @State var minValue = -1

    var calendarAndPicker: some View {
        VStack {
            calendarPickerComponent
            calendarComponent
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    calendarPickerComponent
                    tabView
                    legend.padding(.bottom, 10)
                    VStack(spacing: 0) {
                        Divider()
                            .background(AppColors.green.color)
                        totalView
                    }
                }
            }
            .scrollIndicators(.hidden)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.backgroundLight.color)
            .onAppear {
                Task {
                    amountOfSunflowers = countDayDataEntries()
                    calendarData = await generateCalendarData(for: Date())
                }
            }
            .onChange(of: selection) { oldValue, newValue in
                let change = newValue - oldValue

                withAnimation {
                    currentMonth = changeMonth(by: change)
                }
                let monthsBetween = monthsBetween(startDate: currentMonth, endDate: Date())
                minValue = selection - 1
                numberOfPages = selection + monthsBetween + 1
            }
            .onChange(of: currentMonth) {oldValue, newValue in
                let monthsBetween = monthsBetween(startDate: currentMonth, endDate: Date())
                minValue = selection - 1
                numberOfPages = selection + monthsBetween + 1
                Task {
                    calendarData = await generateCalendarData(for: newValue)
                }
            }
            .navigationDestination(for: Destinations.self) { destination in
                DestinationView(destination: destination)
            }
        }
        .accentColor(AppColors.brown.color)
    }

    var tabView: some View {
        TabView(selection: $selection) {
            ForEach(minValue..<numberOfPages, id: \.self) { index in
                calendarComponent
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: calculateCalendarHeight())
    }

    private func calculateCalendarHeight() -> CGFloat {
//        let rowHeight = calculateRowHeight()
        let numberOfCalendarRows = calculateNumberOfRows()
//        let totalRows: CGFloat = CGFloat(numberOfCalendarRows) + 2
//        return rowHeight * totalRows + (totalRows) * 5
        let totalRows = numberOfCalendarRows + 1
        return CGFloat(totalRows * 70 + totalRows * 5)
    }

    var calendarPickerComponent: some View {
        HStack {
            Button(action: {
                withAnimation {
                    currentMonth = changeMonth(by: -1)
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.body)
                    .padding()
                    .foregroundStyle(AppColors.green.color)
            }

            Spacer()

            Text(monthYearString(for: currentMonth))
                .foregroundStyle(AppColors.green.color)
                .font(.title)
                .padding()

            Spacer()
                Button(action: {
                    if currentMonth.isSameMonth(as: Date()) {
                        return
                    }
                    withAnimation {
                        currentMonth = changeMonth(by: 1)
                    }
                }) {
                    if !currentMonth.isSameMonth(as: Date()) {
                        Image(systemName: "chevron.right")
                            .font(.body)
                            .padding()
                            .foregroundStyle(AppColors.green.color)
                    } else {
                        Text("")
                            .font(.body)
                            .padding()
                    }
                }
        }
    }

    var calendarComponent: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .center), count: 7)
        let rowHeight: CGFloat = 70

        return VStack(spacing: 10) {
            // Weekday header
            HStack {
                ForEach(0..<7, id: \.self) { index in
                    Text(weekdayString(for: index))
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(AppColors.green.color)
                        .font(.headline)
                }
            }

            LazyVGrid(columns: columns, spacing: 10) {
                let calendarDays = getCalendarDays(for: calendarData)
                ForEach(Array(calendarDays.enumerated()), id: \.offset) { index, calendarDay in
                    if let day = calendarDay.day {
                        DayView(day: day)
                    } else {
                        Text("")
                            .frame(height: rowHeight)
                    }
                }
            }
        }
    }

    var legend: some View {
        VStack(alignment: .leading, spacing: 5) {
            LegendItem(color: AppColors.blue.color, text: "Sunflower picked", emoji: "🌻")
            LegendItem(color: AppColors.white.color, text: "Sunflower grew but not picked", emoji: "🌞")
            LegendItem(color: AppColors.red.color, text: "Sunflower didn't get enough sun", emoji: "☁️")
        }
        .foregroundStyle(AppColors.green.color)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var totalView: some View {
        HStack() {
            VStack(alignment: .center) {
                Text("\(streakCount.todayStreak) 🔥")
                    .foregroundStyle(AppColors.green.color)
                    .font(.title)
                Text("Picked sunflowers\nstreak")
                    .foregroundStyle(AppColors.green.color)
                    .multilineTextAlignment(.center)

            }
            Spacer()
            Divider()
                .background(AppColors.green.color)
                .padding(.horizontal)
            Spacer()
            NavigationLink(value: Destinations.field(number: amountOfSunflowers)) {
                HStack(spacing: 0) {
                    VStack(alignment: .center) {
                        Text("\(amountOfSunflowers) 🌻")
                            .foregroundStyle(AppColors.green.color)
                            .font(.title)
                        Text("Total picked\nsunflowers")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppColors.green.color)
                    }
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .padding(.leading)
                        .foregroundStyle(AppColors.green.color)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

extension CalendarView {

    private func calculateNumberOfRows() -> Int {
        let calendar = Calendar.current
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let numberOfDays = calendar.range(of: .day, in: .month, for: currentMonth)!.count
        let numberOfRows = Int(ceil(Double(firstWeekday - 1 + numberOfDays) / 7.0))
        return numberOfRows
    }

    func monthsBetween(startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current

        let startComponents = calendar.dateComponents([.year, .month], from: startDate)
        let endComponents = calendar.dateComponents([.year, .month], from: endDate)

        let totalMonths = (endComponents.year! - startComponents.year!) * 12 + (endComponents.month! - startComponents.month!)

        return totalMonths
    }

    private func changeMonth(by offset: Int) -> Date {
        return Calendar.current.date(byAdding: .month, value: offset, to: currentMonth) ?? currentMonth
    }

    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func weekdayString(for index: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.shortWeekdaySymbols[index]
    }

    private func generateCalendarData(for month: Date) async -> [CalendarModel] {
        let calendar = Calendar.current
        let today = Date()

        let range = calendar.range(of: .day, in: .month, for: month)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!

        var calendarData: [CalendarModel] = []

        for day in range {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)!
            let isFuture = calendar.compare(date, to: today, toGranularity: .day) == .orderedDescending
            let isToday = calendar.isDateInToday(date)

            // Fetch the time in sunlight asynchronously
            let timeInSun = await sunWorker.getSunTime(for: date) ?? 0
            let isPicked = await checkIfDayDataExists(for: date)
            let goalAchieved = timeInSun >= userInfo.sunGoal
            // Create the CalendarModel object
            let calendarModel = CalendarModel(
                date: date,
                isPicked: isPicked,
                isFuture: isFuture,
                isToday: isToday,
                goalAchieved: goalAchieved,
                timeInMinutes: timeInSun
            )

            // Append to the array
            calendarData.append(calendarModel)
        }

        return calendarData
    }

    private func checkIfDayDataExists(for date: Date) async -> Bool {
        let calendar = Calendar.current
        let startOfDay = date.startOfDay
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date().addingTimeInterval(86400)
        let fetchDescriptor = FetchDescriptor<DayData>(
            predicate: #Predicate { dayData in
                dayData.date >= startOfDay && dayData.date < tomorrow
            }
        )

        do {
            // Perform the fetch operation
            let results = try modelContext.fetch(fetchDescriptor)

            // Return true if a DayData entry exists for this date, otherwise false
            return !results.isEmpty
        } catch {
            print("Error fetching DayData: \(error)")
            return false
        }
    }
    private func countDayDataEntries() -> Int {
        let fetchDescriptor = FetchDescriptor<DayData>()

        do {
            // Perform the fetch operation and count the results
            let count = try modelContext.fetchCount(fetchDescriptor)
            return count
        } catch {
            print("Error fetching DayData count: \(error)")
            return 0
        }
    }

    private func getCalendarDays(for calendarData: [CalendarModel]) -> [CalendarDay] {
        guard let firstDay = calendarData.first?.date,
              let lastDay = calendarData.last?.date else {
            return []
        }

        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Start the week on Sunday

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let numberOfLeadingEmptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7

        var days: [CalendarDay] = []

        // Add leading empty days
        for _ in 0..<numberOfLeadingEmptyDays {
            days.append(CalendarDay(day: nil))
        }

        // Add days of the month
        for day in calendarData {
            days.append(CalendarDay(day: day))
        }

        // Add trailing empty days to complete the last row, if necessary
        let remainingDays = (7 - (days.count % 7)) % 7
        for _ in 0..<remainingDays {
            days.append(CalendarDay(day: nil))
        }

        return days
    }
}

#Preview {
    // Example calendar data
    let calendar = Calendar.current
    let today = Date()
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DayData.self, configurations: config)
    let userInfo = UserInfo()

    let exampleData = (1...calendar.range(of: .day, in: .month, for: today)!.count).map { day -> CalendarModel in
        let date = calendar.date(byAdding: .day, value: day - calendar.component(.day, from: today), to: today)!
        let isFilled = day % 2 == 0
        let isFuture = calendar.compare(date, to: today, toGranularity: .day) == .orderedDescending
        let isToday = calendar.isDateInToday(date)
        return CalendarModel(
            date: date,
            isPicked: isFilled,
            isFuture: isFuture,
            isToday: isToday,
            goalAchieved: true,
            timeInMinutes: 14223
        )
    }

    let healthStoreManager = HealthStoreManager()
    let sunWorker = SunWorker(healthManager: healthStoreManager)

    return CalendarView()
        .background(AppColors.backgroundLight.color)
        .environmentObject(sunWorker)
        .environmentObject(userInfo)
        .modelContainer(container)
}
