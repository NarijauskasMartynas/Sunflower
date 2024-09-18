import SwiftUI

struct SunGoalPicker<Content: View>: View {
    @EnvironmentObject var userInfo: UserInfo
    @EnvironmentObject var watchManager: WatchManager

    @State private var selectedSunGoal: Int = 0
    @State var isPickerPresented: Bool = false

    // A closure that returns the custom view
    let content: () -> Content

    var body: some View {
        content()
            .onTapGesture {
                isPickerPresented = true
            }
            .sheet(isPresented: $isPickerPresented) {
                NumberPicker(
                    selection: $selectedSunGoal,
                    title: "Select your daily goal of sun (minutes)",
                    startValue: 1,
                    endValue: 300,
                    onClose: {
                        print(selectedSunGoal)
                        let selectedDoubleGoal = Double(selectedSunGoal * 60)
                        userInfo.sunGoal = selectedDoubleGoal
                        watchManager.sendSunGoal(sunGoal: selectedDoubleGoal)
                        isPickerPresented = false
                    }
                )
                .presentationDetents([.medium])
            }
            .onAppear() {
                selectedSunGoal = Int(userInfo.sunGoal / 60.0)
            }
            .onChange(of: selectedSunGoal) {
                print(selectedSunGoal)
                userInfo.sunGoal = Double(selectedSunGoal * 60)
            }
    }
}

#Preview {
    SunGoalPicker {
        Text("Test")
    }
        .environmentObject(UserInfo())
        .background(AppColors.backgroundLight.color)
}
