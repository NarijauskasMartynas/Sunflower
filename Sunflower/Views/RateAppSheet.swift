import SwiftUI
import FirebaseFirestore
import Lottie

struct RateAppSheet: View {
    let onReview: () -> Void
    let onCancel: () -> Void
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack {
            VStack(alignment: .center) {
                Text("Help our Sunflower grow by giving us 5 stars! ❤️")
                    .font(.title)
                    .foregroundStyle(AppColors.green.color)
                LottieView(animation: .named("SunflowerMain"))
                    .playing(loopMode: .playOnce)

            }
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    onCancel()
                }) {
                    Text("NO! 😢")
                        .padding(5)
                }
                .buttonStyle(SecondaryButtonStyle())
                Spacer()
                Button(action: {
                    onReview()
                }) {
                    Text("REVIEW! ⭐️")
                        .padding(5)
                }
                .buttonStyle(PrimaryButtonStyle())
                Spacer()
            }

        }
        .padding()
        .background(AppColors.backgroundLight.color)
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    RateAppSheet(
        onReview: {},
        onCancel: {}
    )
}
