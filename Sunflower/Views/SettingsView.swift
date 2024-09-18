import SwiftUI
import RevenueCat

enum SettingsSheetType: Identifiable {
    case privacyPolicy
    case termsAndConditions

    var id: String {
        switch self {
        case .privacyPolicy:
            return "privacyPolicy"
        case .termsAndConditions:
            return "termsAndConditions"
        }
    }

    var urlString: String {
        switch self {
        case .privacyPolicy:
            "https://sunflower-app.com/privacy-policy/"
        case .termsAndConditions:
            "https://sunflower-app.com/terms-and-conditions/"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var userInfo: UserInfo
    @EnvironmentObject var subscriptionsManager: SubscriptionsManager
    @State private var sheetType: SettingsSheetType?

    @State private var selectedSunGoal: Int = 0
    @State private var isSubscriptionsSheetShown: Bool = false
    @State private var isFeedbackFormShown: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SETTINGS")
                .font(.title)
                .padding(.bottom, 5)
                .foregroundStyle(AppColors.green.color)
            // Sun Goal Picker
            VStack(spacing: 0) {
                sunGoalPicker
                    .clipShape(
                        .rect(
                            topLeadingRadius: 10,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 10
                        )
                    )
                Divider()
                    .foregroundStyle(AppColors.green.color)
                // Subscriptions Section
                if subscriptionsManager.proType != .allTime {
                    subscriptions
                    Divider()
                        .foregroundStyle(AppColors.green.color)
                }
                shareFeedback
                    .clipShape(
                        .rect(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 10,
                            bottomTrailingRadius: 10,
                            topTrailingRadius: 0
                        )
                    )
            }

            sheets

            Spacer()
            Text(Purchases.shared.appUserID)
                .foregroundStyle(AppColors.white.color)
                .font(.footnote)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .fullScreenCover(isPresented: $isSubscriptionsSheetShown) {
            SubscriptionView(isFirst: false, isForce: false) {
                isSubscriptionsSheetShown = false
            }
        }
        .sheet(isPresented: $isFeedbackFormShown) {
            FeedbackSheet() {
                isFeedbackFormShown = false
            }
        }
        .sheet(item: $sheetType, content: { item in
            WebView(urlString: item.urlString) {
                sheetType = nil
            }.edgesIgnoringSafeArea(.all)
        })
    }

    var sunGoalPicker: some View {
        SunGoalPicker {
            HStack {
                Text("🌞 SUN GOAL")
                    .font(.headline)
                    .foregroundColor(AppColors.green.color)
                Spacer()
                Text("\(userInfo.sunGoal.hoursMinutes())")
                    .font(.headline)
                    .foregroundColor(AppColors.green.color)
                Image(systemName: "chevron.right")
                    .frame(width: 20, height: 20)
                    .foregroundStyle(AppColors.green.color)
            }
            .padding(15)
            .background(AppColors.white.color)
            .contentShape(Rectangle()) // Ensure the entire area is tappable
        }
    }

    var subscriptions: some View {
        HStack {
            Text("💰 SUBSCRIPTIONS")
                .font(.headline)
                .foregroundStyle(AppColors.green.color)
            Spacer()
            Image(systemName: "chevron.right")
                .frame(width: 20, height: 20)
                .foregroundStyle(AppColors.green.color)
        }
        .padding(15)
        .background(AppColors.white.color)
        .onTapGesture {
            isSubscriptionsSheetShown = true
        }
    }

    var shareFeedback: some View {
        HStack {
            Text("🫶 SHARE FEEDBACK")
                .font(.headline)
                .foregroundStyle(AppColors.green.color)
            Spacer()
            Image(systemName: "chevron.right")
                .frame(width: 20, height: 20)
                .foregroundStyle(AppColors.green.color)
        }
        .padding(15)
        .background(AppColors.white.color)
        .onTapGesture {
            isFeedbackFormShown = true
        }
    }

    var sheets: some View {
        VStack(spacing: 0) {
            HStack {
                Text("📃 PRIVACY POLICY")
                    .font(.headline)
                    .foregroundStyle(AppColors.green.color)
                Spacer()
                Image(systemName: "chevron.right")
                    .frame(width: 20, height: 20)
                    .foregroundStyle(AppColors.green.color)
            }
            .padding(15)
            .background(AppColors.white.color)
            .onTapGesture {
                sheetType = .privacyPolicy
            }
            .clipShape(
                .rect(
                    topLeadingRadius: 10,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 10
                )
            )
            Divider()
                .foregroundStyle(AppColors.green.color)
            HStack {
                Text("📃 TERMS AND CONDITIONS")
                    .font(.headline)
                    .foregroundStyle(AppColors.green.color)
                Spacer()
                Image(systemName: "chevron.right")
                    .frame(width: 20, height: 20)
                    .foregroundStyle(AppColors.green.color)
            }
            .padding(15)
            .background(AppColors.white.color)
            .onTapGesture {
                sheetType = .termsAndConditions
            }
            .clipShape(
                .rect(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 10,
                    bottomTrailingRadius: 10,
                    topTrailingRadius: 0
                )
            )
        }
    }
}


//#Preview {
//    SettingsView()
//        .environmentObject(UserInfo())
//        .background(AppColors.backgroundLight.color)
//        .environmentObject(HealthStoreManager())
//        .environmentObject(SubscriptionsManager(watchManager: WatchManager(), userInfo: UserInfo()))
//}

struct NumberPicker: View {
    @Binding var selection: Int
    let title: String
    let startValue: Int
    let endValue: Int
    let onClose: () -> Void
    var range: Range<Int> {
        startValue..<endValue
    }

    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .foregroundStyle(AppColors.green.color)
                .font(.title2)
            Picker("Sun Daily Goal", selection: $selection) {
                ForEach(range, id: \.self) { rate in
                    Text("\(rate)").tag(rate)
                        .foregroundStyle(AppColors.green.color)
                }
            }
            .pickerStyle(.wheel)
            .clipped()
            Spacer()
            Button(action: {
                onClose()
            }) {
                Text("CLOSE")
                    .frame(width: UIScreen.main.bounds.width * 0.5)
            }
            .buttonStyle(PrimaryButtonStyle())

        }
        .background(AppColors.backgroundLight.color)
        .frame(maxHeight: .infinity)
    }
}
