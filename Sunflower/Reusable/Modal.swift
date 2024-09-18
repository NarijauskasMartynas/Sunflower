import SwiftUI

struct Modal<Content: View>: View {
    let content: Content
    let spacing: CGFloat
    let onBackgroundTap: () -> Void

    init(spacing: CGFloat = 30, onBackgroundTap: @escaping () -> Void = {}, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.spacing = spacing
        self.onBackgroundTap = onBackgroundTap
    }


    var body: some View {
        ZStack {
            Color(.black).ignoresSafeArea().opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onBackgroundTap() // Call the action when background is tapped
                }
            VStack(spacing: spacing) {
                content
            }

            .frame(width: UIScreen.main.bounds.width / 1.3)
            .padding(20)
            .background(AppColors.backgroundLight.color)
            .cornerRadius(20)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white)
                    .shadow(color: AppColors.green.color, radius: 2, x: 1, y: 1)
            )
            .transition(.scale)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
        }.background(.clear)
    }
}
