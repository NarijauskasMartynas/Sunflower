import SwiftUI
import RevenueCat
import WidgetKit
import SwiftData
import Lottie
import FirebaseAnalytics

struct SunflowerView: View {
    @EnvironmentObject
    var userInfo: UserInfo

    @EnvironmentObject
    var sunWorker: SunWorker

    @EnvironmentObject
    var healthStoreManager: HealthStoreManager

    @EnvironmentObject
    var backgroundNotificationsWorker: BackgroundNotificationsWorker

    @EnvironmentObject
    var watchManager: WatchManager

    @EnvironmentObject
    var subscriptionsManager: SubscriptionsManager

    @Environment(\.modelContext) private var modelContext

    @FetchTodayData private var todayData: DayData?

    @Environment(\.scenePhase) var scenePhase

    @Environment(\.requestReview)
    var requestReview

    @AppStorage(DefaultKeys.sunGoal.rawValue, store: UserDefaults(suiteName: DefaultKeys.suite.rawValue))
    var sunGoal: Double = 30 * 60

    @FetchStreakData
    private var streakCount

    // Data
    @State private var currentSunExposureTime: Double = 0

    // Animations
    @State private var sunflowerState: SunflowerGrown = .sad
    @State private var startInput: Int = 0
    @State private var endInput: Int = 100
    @State private var startFrame: CGFloat = 0
    @State private var endFrame: CGFloat = 1
    @State private var isFirstRun = true
    @State private var isStoped = true
    @State var playbackMode = LottiePlaybackMode.paused(at: .progress(0))

    @State var showStreakSheet: Bool = false
    @State private var isSubscriptionsSheetShown: Bool = false
    @State private var isReviewSheetShown: Bool = false
    @State private var isForced: Bool = false
    @State private var isFeedbackFormShown: Bool = false

    @State var isDebug: Bool = true

    var body: some View {
        mainView
            .onAppear() {
                Task {
                    await handleFirstLoad()
                }
            }
            .onChange(of: scenePhase) {oldValue, newValue in
                if oldValue == .inactive && newValue == .active {
                    Task {
                        await handleOnAppear()
                    }
                }
            }

            .fullScreenCover(isPresented: $showStreakSheet) {
                StreakModal() {
                    showStreakSheet = false
                }.presentationBackground(.clear)
            }
            .fullScreenCover(isPresented: $isSubscriptionsSheetShown){
                SubscriptionView(isFirst: true, isForce: isForced) {
                    isSubscriptionsSheetShown = false
                }
            }
            .fullScreenCover(isPresented: $isReviewSheetShown){
                RateAppSheet(
                    onReview: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isReviewSheetShown = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            requestReview()
                            userInfo.gaveReview = true
                        }
                    },
                    onCancel: {
                        userInfo.launchCount = 0
                        userInfo.nextAlertLaunchCount = 10

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isReviewSheetShown = false
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isFeedbackFormShown = true
                        }
                    }
                )
            }
            .sheet(isPresented: $isFeedbackFormShown) {
                FeedbackSheet() {
                    isFeedbackFormShown = false
                }
            }
    }

    var pickedSunflowerButton: some View {
        VStack(alignment: .center, spacing: 10) {
            ZStack {
                GeometryReader { geometry in
                    LottieView(animation: .named("confetiAnimation"))
                        .playing(loopMode: .playOnce)
                        .opacity(1)
                        .frame(height: geometry.size.height)
                        .clipped()
                }
                VStack {
                    Text("You already picked your sunflower!")
                        .foregroundStyle(AppColors.green.color)
                        .font(.title3)
                    Text("Come back tomorrow!")
                        .foregroundStyle(AppColors.green.color)
                        .font(.title3)
                }
            }
        }
    }


    var grownSunflowerButton: some View {
        VStack {
            Text("Your sunflower has grown!")
                .foregroundStyle(AppColors.green.color)
                .font(.title3)
            Button(
                action: {
                    let today = Date()
                    let newDayData = DayData(date: today)
                    modelContext.insert(newDayData)
                    userInfo.lastPickedDateValue = today
                    showStreakSheet = true
                    watchManager.sendLastPickedSunflowerDate(date: today)
                }){
                    Text("PICK IT!")
                }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    func calculatePercentage(current: Double, goal: Double) -> Double {
        guard goal != 0 else {
            return 0
        }
        return (current / goal) * 100
    }
}

extension SunflowerView {
    func handleFirstLoad() async {
        backgroundNotificationsWorker.subscribeToNotifications()
        await handleOnAppear()
    }

    func handleOnAppear() async {
        if userInfo.onboardingDateValue == nil {
            isSubscriptionsSheetShown = true
            userInfo.onboardingDateValue = Date()
        } else if streakCount.yesterdayStreak > 0 && streakCount.todayStreak == 0 && shouldShowStreakLoss() {
            showStreakSheet = true
            userInfo.lastStreakLossShownDate = Date()
        } else if !userInfo.gaveReview && userInfo.launchCount >= userInfo.nextAlertLaunchCount {
            isReviewSheetShown = true
        }

        Task {
            await fetchSun()
        }
    }

    func shouldShowStreakLoss() -> Bool {
        guard let lastShownDate = userInfo.lastStreakLossShownDate else {
            return true // Never shown before
        }

        let calendar = Calendar.current
        return !calendar.isDateInToday(lastShownDate)
    }

    func fetchSun() async {
        let timeInSun = await sunWorker.getSunTime(for: Date()) ?? 0

        // Widget related data
        userInfo.timeInSun = timeInSun
        WidgetCenter.shared.reloadAllTimelines()

        self.currentSunExposureTime = timeInSun

        watchManager.sendTimeInSun(timeInSun: timeInSun)
        watchManager.sendIsPro(isPro: subscriptionsManager.proType != .none)
        watchManager.sendSunGoal(sunGoal: userInfo.sunGoal)
        if let lastPickedDateValue = userInfo.lastPickedDateValue {
            watchManager.sendLastPickedSunflowerDate(date: lastPickedDateValue)
        }

        var endProgress: Double = 0
        if timeInSun > 0 {
            let percentage = Double(timeInSun / sunGoal) * 100
            print("PERCENTAGE: \(percentage)")
            let sunflowerGrownState = SunflowerGrown.getStateByPercentage(percentage: percentage)
            endProgress = sunflowerGrownState.endFrame
            sunflowerState = sunflowerGrownState
        } else {
            endProgress = SunflowerGrown.sad.endFrame
            sunflowerState = .sad
        }

        endFrame = endProgress

        playbackMode = .playing(
            .fromProgress(
                startFrame,
                toProgress: endProgress,
                loopMode: .playOnce
            )
        )
    }

    var mainView: some View {
        ProportionalLayout([0.2, 0.6, 0.2], alignment: .center) {
            SunProgressView(currentSunGoal: $currentSunExposureTime, sunGoal: userInfo.sunGoal)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            LottieView(animation: .named("SunflowerMain"))
                .playbackMode(playbackMode)
                .animationSpeed(isFirstRun ? 1 : sunflowerState.animationSpeed)

                .animationDidFinish { _ in
                    print("ANIMATION FINISHED")
                    isFirstRun = false
                    playbackMode = .playing(
                        .fromProgress(sunflowerState.endFrame, toProgress: sunflowerState.startFrame, loopMode: .autoReverse)
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack {
                if todayData != nil {
                    pickedSunflowerButton
                } else if userInfo.sunGoal <= currentSunExposureTime {
                    grownSunflowerButton
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

enum SunflowerGrown {
    case sad
    case mid
    case happy
    case grown

    var startFrame: CGFloat {
        switch self {
        case .sad:
            return 0.0
        case .mid:
            return 0.09
        case .happy:
            return 0.22
        case .grown:
            return 0.6
        }
    }

    var endFrame: CGFloat {
        switch self {
        case .sad:
            return 0.05
        case .mid:
            return 0.13
        case .happy:
            return 0.25
        case .grown:
            return 1
        }
    }

    var animationSpeed: Double {
        switch self {
        case .sad:
            return 0.7
        case .mid:
            return 0.5
        case .happy:
            return 0.5
        case .grown:
            return 1
        }
    }

    static func getStateByPercentage(percentage: Double) -> SunflowerGrown {
        switch percentage {
        case ..<0:
            return .sad
        case 0..<30:
            return .sad
        case 30..<60:
            return .mid
        case 60..<99:
            return .happy
        case 99...(.infinity):
            return .grown
        case _ where percentage.isNaN:
            return .sad
        case _:
            return .sad
        }
    }
}

//extension SunflowerView {
//    static func prepareForPreview() -> some View {
//        let healthStoreManager = HealthStoreManager()
//        let sunWorker = SunWorker(healthManager: healthStoreManager)
//        let userInfo = UserInfo()
//        let subscriptionsManager = SubscriptionsManager(watchManager: WatchManager(), userInfo: userInfo)
//
//        return SunflowerView()
//            .environmentObject(healthStoreManager)
//            .environmentObject(sunWorker)
//            .environmentObject(userInfo)
//            .environmentObject(subscriptionsManager)
//    }
//}
//
//#Preview {
//    let config = ModelConfiguration(isStoredInMemoryOnly: true)
//    let container = try! ModelContainer(for: DayData.self, configurations: config)
//
//    return SunflowerView.prepareForPreview()
//        .background(AppColors.backgroundLight.color)
//        .modelContainer(container)
//}

struct ProportionalLayout: Layout {
    var proportions: [CGFloat]
    var spacing: CGFloat
    var alignment: HorizontalAlignment

    init(_ proportions: [CGFloat], spacing: CGFloat = 0, alignment: HorizontalAlignment = .center) {
        self.proportions = proportions
        self.spacing = spacing
        self.alignment = alignment
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        return proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty, !proportions.isEmpty else { return }

        let totalProportion = proportions.reduce(0, +)
        let totalSpacing = spacing * CGFloat(subviews.count - 1)
        var y = bounds.minY

        for (index, subview) in subviews.enumerated() {
            guard index < proportions.count else { break }

            let proportion = proportions[index] / totalProportion
            let height = (bounds.height - totalSpacing) * proportion

            let subviewWidth = subview.sizeThatFits(.unspecified).width
            let x: CGFloat
            switch alignment {
            case .leading:
                x = bounds.minX
            case .trailing:
                x = bounds.maxX - subviewWidth
            default:
                x = bounds.midX - subviewWidth / 2
            }

            let frame = CGRect(x: x, y: y, width: subviewWidth, height: height)
            subview.place(at: frame.origin, proposal: ProposedViewSize(frame.size))

            y += height + spacing
        }
    }
}

struct LottieControlView: View {
    @State private var sliderValue: Double = 0
    @State private var playbackMode: LottiePlaybackMode = .paused(at: .progress(0))

    var body: some View {
        VStack {
            LottieView(animation: .named("SunflowerMain"))
                .playbackMode(playbackMode)
                .frame(height: 300)

            Slider(value: $sliderValue, in: 0...1, step: 0.01)
                .padding()
                .onChange(of: sliderValue) { oldValue, newValue in
                    updateAnimation(to: newValue)
                }

            Text("Current Progress: \(sliderValue, specifier: "%.2f")")
                .padding()
        }
    }

    func updateAnimation(to value: Double) {
        playbackMode = .paused(at: .progress(value))
        print("Current Progress: \(value)")
        print("Current Percentage: \(Int(value * 100))%")

        let state = SunflowerGrown.getStateByPercentage(percentage: value * 100)
        print("Current State: \(state)")
    }
}
