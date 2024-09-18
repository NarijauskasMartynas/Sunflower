import SwiftUI

struct Sunflower: Identifiable {
    let id = UUID()
    var xPosition: CGFloat
    var yPosition: CGFloat
    var finalYPosition: CGFloat
    var delay: Double
}

struct SunflowerMiniView: View {
    var body: some View {
        Text("🌻")
            .font(.title)
    }
}

struct SunflowersField: View {
    let numberOfSunflowers: Int
    @State private var sunflowers: [Sunflower] = []
    @State private var visibleSunflowers: Set<UUID> = []
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Static background
                AppColors.green.color
                    .edgesIgnoringSafeArea(.vertical)

                if sunflowers.isEmpty {
                    Text("Your Sunflowers field is empty! \nGrow and pick your sunflowers to see it here!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppColors.brown.color)
                }
                ForEach(sunflowers) { sunflower in
                    if visibleSunflowers.contains(sunflower.id) {
                        SunflowerMiniView()
                            .position(x: sunflower.xPosition, y: sunflower.yPosition)
                            .animation(.easeInOut(duration: 1.0), value: sunflower.yPosition)
                    }
                }
            }
            .onAppear {
                generateSunflowers(geometry: geometry)
                animateSunflowers()
            }
        }
        .toolbar(.hidden, for: .tabBar)
//        .navigationBarHidden(true)
    }

    private func generateSunflowers(geometry: GeometryProxy) {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height - geometry.size.height * 0.15
        let delayIncrement = 0.01 // Adjust this for faster/slower appearance
        sunflowers = (0..<numberOfSunflowers).map { index in
            let randomX = CGFloat.random(in: 5...screenWidth - 5)
            let initialY = -50.0 // Start just off the screen
            let finalY = CGFloat.random(in: 0...(screenHeight))
            let delay = Double(index) * delayIncrement

            return Sunflower(xPosition: randomX, yPosition: initialY, finalYPosition: finalY, delay: delay)
        }
    }

    // Function to animate sunflowers
    private func animateSunflowers() {
        for sunflower in sunflowers {
            DispatchQueue.main.asyncAfter(deadline: .now() + sunflower.delay) {
                visibleSunflowers.insert(sunflower.id)
                feedbackGenerator.impactOccurred()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                    if let index = sunflowers.firstIndex(where: { $0.id == sunflower.id }) {
                        sunflowers[index].yPosition = sunflowers[index].finalYPosition
                    }
                }
            }
        }
    }
}

#Preview {
    SunflowersField(numberOfSunflowers: 150)
}
