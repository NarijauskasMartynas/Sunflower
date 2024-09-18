import SwiftUI
import Lottie

struct GlobalLoaderOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
            VStack {
                LottieView(animation: .named("LoadingAnimation"))
                    .playing(loopMode: .autoReverse)
                    .frame(height: 500)
                Text("We're growing your sunflower!\nPlease wait!")
                    .foregroundStyle(AppColors.white.color)
                    .font(.title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
            }.padding(.horizontal)
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    GlobalLoaderOverlay()
}
