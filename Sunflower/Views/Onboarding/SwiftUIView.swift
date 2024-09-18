import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case sunflowerFacesSun = 0
    case vitaminD
    case dailyGoal
    case appleWatch
    case notifications
    case final
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
    let backgroundImageName: String
    let fullWidthImg: Bool
}

struct OnboardingScroller: View {
    @EnvironmentObject
    var appState: AppState
    @State private var currentPage: OnboardingStep = .sunflowerFacesSun
    @State private var pageVisited = [Bool](repeating: false, count: 6)
    
    @State var scrollId: Int?

    let onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Did you know, that sunflowers always face the sun?",
            subtitle: "Grow your sunflower by getting your daily goal of sun exposure",
            imageName: "facesSun",
            backgroundImageName: "branch",
            fullWidthImg: true
        ),
        OnboardingPage(
            title: "Sun is the best natural source of vitamin D",
            subtitle: "Vitamin D is important for strong bones, muscles and overall health",
            imageName: "vitaminD",
            backgroundImageName: "branch",
            fullWidthImg: false
        ),
        OnboardingPage(
            title: "Everyone goal is different. Usually it's 15-30 minutes", 
            subtitle: "Select your daily sun goal!", 
            imageName: "differentSeeds",
            backgroundImageName: "branch",
            fullWidthImg: false
        ),
        OnboardingPage(
            title: "Use your Apple Watch to track your sunlight exposure",
            subtitle: "We need your health permission to show you the progress",
            imageName: "watch",
            backgroundImageName: "branch",
            fullWidthImg: true
        ),
        OnboardingPage(
            title: "Stay notified when to pick your sunflower!", 
            subtitle: "We promise, we won't spam you!",
            imageName: "notifications",
            backgroundImageName: "branch",
            fullWidthImg: false
        ),
        OnboardingPage(
            title: "Enjoy the sunflower",
            subtitle: "", imageName: "",
            backgroundImageName: "flower",
            fullWidthImg: false
        )
    ]

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(OnboardingStep.allCases, id: \.self) { step in
                            OnboardingPageView(
                                page: pages[step.rawValue],
                                isLastPage: step.rawValue == pages.count - 1,
                                geometry: geometry,
                                currentPage: $currentPage,
                                pageVisited: $pageVisited[step.rawValue], // Track if the page was visited
                                stepType: step
                            ) {
                                if let nextPage = OnboardingStep(rawValue: currentPage.rawValue + 1) {
                                    withAnimation {
                                        currentPage = nextPage
                                        proxy.scrollTo(currentPage.rawValue, anchor: .center)
                                    }
                                } else {
                                    onComplete()
                                }
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .id(step.rawValue)
                        }
                    }.scrollTargetLayout()
                }
                .onChange(of: scrollId ?? 0) { _, new in
                    currentPage = OnboardingStep(rawValue: new) ?? .sunflowerFacesSun
                }
                .onAppear() {
                    pageVisited = [Bool](repeating: false, count: pages.count)
                }
                .scrollPosition(id: $scrollId)
                .scrollTargetBehavior(.paging)
                .rotationEffect(.degrees(180))
                .scaleEffect(x: -1, y: 1, anchor: .center)
            }
        }
        .background(AppColors.backgroundLight.color)
        .edgesIgnoringSafeArea(.all)
    }
}

struct OnboardingPageView: View {
    @EnvironmentObject
    var healthStoreManager: HealthStoreManager

    @EnvironmentObject
    var appState: AppState

    @EnvironmentObject
    var userInfo: UserInfo

    @EnvironmentObject
    var backgroundNotificationsWorker: BackgroundNotificationsWorker

    let page: OnboardingPage
    let isLastPage: Bool
    let geometry: GeometryProxy
    @Binding var currentPage: OnboardingStep
    @Binding var pageVisited: Bool // Track if the page was visited
    let stepType: OnboardingStep
    let onNextTapped: () -> Void

    @State private var isTitleVisible = false
    @State private var isImageVisible = false
    @State private var isSubtitleVisible = false
    @State private var isButtonVisible = false

    var body: some View {
        ZStack {
            Image(page.backgroundImageName)
                .resizable()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(x: -geometry.safeAreaInsets.leading)
                .rotationEffect(.degrees(180))
                .scaleEffect(x: -1, y: 1, anchor: .center)
                .opacity(1)
            VStack {
                if stepType == .dailyGoal {
                    goalPickerView
                } else if stepType == .final {
                    VStack {
                        Spacer()
                        Text("Enjoy the Sunflower!")
                            .font(.title)
                            .foregroundStyle(AppColors.green.color)
                            .opacity(isTitleVisible ? 1 : 0)
                            .offset(y: isTitleVisible ? 0 : -20)
                            .animation(.easeInOut(duration: 0.6).delay(0.3), value: isTitleVisible)
                        Spacer()
                        Button(action: onNextTapped) {
                            Text("COMPLETE")
                                .frame(width: geometry.size.width * 0.5)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .frame(width: geometry.size.width * 0.5)
                        .opacity(isButtonVisible ? 1 : 0)
                        .scaleEffect(isButtonVisible ? 1 : 0.8)
                        .animation(.easeInOut(duration: 0.6).delay(0.6), value: isButtonVisible)
                    }
                    .padding(.vertical, geometry.safeAreaInsets.top)
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.6, alignment: .bottom)
                    .padding(.vertical, geometry.safeAreaInsets.top)

                } else {
                    mainView
                }
            }
            .rotationEffect(.degrees(180))
            .scaleEffect(x: -1, y: 1, anchor: .center)
            .onAppear {
                if stepType == currentPage && !pageVisited {
                    animateElements()
                    pageVisited = true // Mark the page as visited after the animation
                } else if pageVisited {
                    setElementsVisible() // Ensure the elements remain visible when scrolling back
                }
            }
            .onChange(of: currentPage) { oldValue, newValue in
                if oldValue == .appleWatch && newValue == .notifications {
                    appState.showLoader = true
                    Task {
                        let _ = await healthStoreManager.requestHealthKitPermissions()
                        backgroundNotificationsWorker.subscribeToNotifications()
                        appState.showLoader = false
                    }
                }

                if oldValue == .notifications && newValue == .final {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                        if success {
                            print("All set!")
                        } else if let error {
                            print(error.localizedDescription)
                        }
                    }
                }
                if stepType == newValue {
                    if !pageVisited {
                        animateElements()
                        pageVisited = true
                    } else {
                        setElementsVisible()
                    }
                } else {
                    resetAnimations()
                }
            }
        }
    }

    var goalPickerView: some View {
        VStack(alignment: .center) {
            Spacer()
            Text(page.title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.green.color)
                .padding(5)
                .background(AppColors.backgroundLight.color)
                .cornerRadius(10)
                .multilineTextAlignment(.center)
                .opacity(isTitleVisible ? 1 : 0)
                .offset(y: isTitleVisible ? 0 : -20)
                .animation(.easeInOut(duration: 0.6).delay(0.3), value: isTitleVisible)

            Text(page.subtitle)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.green.color)
                .padding(5)
                .background(AppColors.backgroundLight.color)
                .cornerRadius(10)
                .multilineTextAlignment(.center)
                .opacity(isSubtitleVisible ? 1 : 0)
                .offset(y: isSubtitleVisible ? 0 : 20)
                .animation(.easeInOut(duration: 0.6).delay(0.9), value: isSubtitleVisible)
                .padding(.top, 30)
            SunGoalPicker() {
                Text(userInfo.sunGoal.hoursMinutes())
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.brown.color)
                    .underline()
            }
            .opacity(isSubtitleVisible ? 1 : 0)
            .offset(y: isSubtitleVisible ? 0 : 20)
            .animation(.easeInOut(duration: 0.6).delay(0.9), value: isSubtitleVisible)


            Spacer()
            if !page.imageName.isEmpty {
                Image(page.imageName)
                    .resizable()
                    .scaledToFit()
                    .if(!page.fullWidthImg) { view in
                        view.frame(width: UIScreen.main.bounds.width * 0.6)
                    }
                    .opacity(isImageVisible ? 0.7 : 0)
                    .scaleEffect(isImageVisible ? 1 : 0.8)
                    .animation(.easeInOut(duration: 0.6).delay(0.6), value: isImageVisible)
            }

            Spacer()
            Button(action: onNextTapped) {
                Text("NEXT")
                    .frame(width: geometry.size.width * 0.5)
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(width: geometry.size.width * 0.5)
            .opacity(isButtonVisible ? 1 : 0)
            .scaleEffect(isButtonVisible ? 1 : 0.8)
            .animation(.easeInOut(duration: 0.6).delay(1.2), value: isButtonVisible)
            Spacer()
        }
        .padding(.horizontal, 30)
        .frame(width: geometry.size.width, height: geometry.size.height)
        .offset(y: geometry.safeAreaInsets.top)
    }

    var mainView: some View {
        VStack(alignment: .center) {
            Spacer()
            Text(page.title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.green.color)
                .padding(5)
                .background(AppColors.backgroundLight.color)
                .cornerRadius(10)
                .multilineTextAlignment(.center)
                .opacity(isTitleVisible ? 1 : 0)
                .offset(y: isTitleVisible ? 0 : -20)
                .animation(.easeInOut(duration: 0.6).delay(0.3), value: isTitleVisible)

//            Spacer()
            if !page.imageName.isEmpty {
                Image(page.imageName)
                    .resizable()
                    .scaledToFit()
                    .if(page.fullWidthImg) { view in
                        view.frame(width: UIScreen.main.bounds.width)
                    }
                    .if(!page.fullWidthImg) { view in
                        view.frame(width: UIScreen.main.bounds.width * 0.6)
                    }
                    .opacity(isImageVisible ? 0.7 : 0)
                    .scaleEffect(isImageVisible ? 1 : 0.8)
                    .animation(.easeInOut(duration: 0.6).delay(0.6), value: isImageVisible)
            }
//            Spacer()
            Text(page.subtitle)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.green.color)
                .padding(5)
                .background(AppColors.backgroundLight.color)
                .cornerRadius(10)
                .multilineTextAlignment(.center)
                .opacity(isSubtitleVisible ? 1 : 0)
                .offset(y: isSubtitleVisible ? 0 : 20)
                .animation(.easeInOut(duration: 0.6).delay(0.9), value: isSubtitleVisible)

            Spacer()

            Button(action: onNextTapped) {
                Text(stepType == .sunflowerFacesSun ? "GET STARTED" : "NEXT")
                    .frame(width: geometry.size.width * 0.5)
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(width: geometry.size.width * 0.5)
            .opacity(isButtonVisible ? 1 : 0)
            .scaleEffect(isButtonVisible ? 1 : 0.8)
            .animation(.easeInOut(duration: 0.6).delay(1.2), value: isButtonVisible)
            Spacer()
        }
        .padding(.horizontal, 30)
        .frame(width: geometry.size.width, height: geometry.size.height)
    }

    private func animateElements() {
        withAnimation(.easeInOut(duration: 0.6).delay(0.3)) {
            isTitleVisible = true
        }
        withAnimation(.easeInOut(duration: 0.6).delay(0.6)) {
            isImageVisible = true
        }
        withAnimation(.easeInOut(duration: 0.6).delay(0.9)) {
            isSubtitleVisible = true
        }
        withAnimation(.easeInOut(duration: 0.6).delay(1.2)) {
            isButtonVisible = true
        }
    }

    private func setElementsVisible() {
        isTitleVisible = true
        isImageVisible = true
        isSubtitleVisible = true
        isButtonVisible = true
    }

    private func resetAnimations() {
        isTitleVisible = false
        isImageVisible = false
        isSubtitleVisible = false
        isButtonVisible = false
    }
}

#Preview {
    OnboardingScroller {
        
    }
    .environmentObject(AppState())
    .environmentObject(UserInfo())
    .environmentObject(HealthStoreManager())
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
