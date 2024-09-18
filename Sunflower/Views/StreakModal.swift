import SwiftUI
import Lottie

struct StreakModal: View {

    @EnvironmentObject
    var userInfo: UserInfo

    @FetchStreakData
    private var streakCount
    @State private var daysPassed: Int = 0
    @State private var lottieFrameHeight: CGFloat = 50

    var hasIncreased: Bool {
        streakCount.todayStreak > streakCount.yesterdayStreak
    }
    let onClose: () -> Void

    var body: some View {
        Modal(onBackgroundTap: { onClose() }) {
            Text(hasIncreased ? "Your streak has increased!" : "You lost your streak 😢")
                .font(.title3)
                .foregroundStyle(AppColors.green.color)
            HStack {
                Text("\(Int(daysPassed))")
                       .font(.largeTitle)
                       .foregroundStyle(AppColors.brown.color)
                       .contentTransition(.numericText())

                LottieView(animation: .named("fireBurning"))
                    .playing(loopMode: .loop)
                    .frame(width: 50, height: lottieFrameHeight)
            }
                .frame(height: 80)
            Button(action: {
                onClose()
            }) {
                Text(hasIncreased ? "KEEP IT BURNING" : "TRY AGAIN")
                    .font(.body)
                    .foregroundStyle(AppColors.white.color)
            }.buttonStyle(PrimaryButtonStyle())
        }
        .onAppear {
            updateDays()
        }
    }

    private func updateDays() {
        daysPassed = streakCount.yesterdayStreak
        withAnimation(.default.delay(0.2).speed(0.3)) {
            daysPassed = streakCount.todayStreak
        }
    }
}

#Preview {
    StreakModal() {}.environmentObject(UserInfo())
}

