import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var backgroundColor: Color = AppColors.green.color
    var foregroundColor: Color = .white
    var cornerRadius: CGFloat = 20
    var horizontalPadding: CGFloat = 30
    var verticalPadding: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var backgroundColor: Color = AppColors.brown.color
    var foregroundColor: Color = .white
    var cornerRadius: CGFloat = 20
    var horizontalPadding: CGFloat = 30
    var verticalPadding: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
