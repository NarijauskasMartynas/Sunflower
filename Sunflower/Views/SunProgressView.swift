import SwiftUI

struct SunProgressView: View {
    @Binding var currentSunGoal: Double
    var sunGoal: Double
    @State private var animatedValue: Double = 0
    @State private var timer: Timer?
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light) // Adjust the style as needed

    var body: some View {
        VStack {
            HStack {
                VStack {
                    HStack {
                        Text("\(animatedValue.hoursMinutes())")
                            .font(.title)
                            .fontWeight(.semibold)
                        Text("/")
                            .font(.title)
                        Text(sunGoal.hoursMinutes())
                            .font(.title)
                    }
                    Text("Time spent in sun")
                        .font(.body)
                }
                .foregroundStyle(AppColors.green.color)
            }
        }
        .onChange(of: currentSunGoal) {_, newValue in
            startAnimation()
        }
        .frame(maxWidth: .infinity)
    }

    func startAnimation() {
        timer?.invalidate()
        animatedValue = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            withAnimation(.bouncy) {
                if animatedValue < currentSunGoal {
                    animatedValue += currentSunGoal / 60 // adjust increment as needed
//                    if animatedValue.truncatingRemainder(dividingBy: 3) == 0 {
                        feedbackGenerator.impactOccurred()
//                    }
                } else {
                    timer?.invalidate()
                }
            }
        }
    }
}
