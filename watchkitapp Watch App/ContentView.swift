import SwiftUI
import WidgetKit

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase

    @EnvironmentObject
    var watchUserInfo: WatchUserInfo

    @EnvironmentObject
    var healthStoreManager: HealthStoreManager

    @EnvironmentObject
    var watchToAppManager: WatchToAppManager

    @EnvironmentObject
    var sunWorker: SunWorker

    @State
    var timeInSun: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    Spacer(minLength: 0)
                    if watchUserInfo.isPro {
                        sunflowerView
                    } else {
                        lockedView
                    }
                    Spacer(minLength: 0)
                }
                .frame(minHeight: geometry.size.height)
            }
            .background(AppColors.backgroundLight.color)
            .toolbar(.hidden)
            .onChange(of: scenePhase) { oldValue, newValue in
                if newValue == .active && oldValue == .inactive {
                    Task {
                        await handleOnLoad()
                    }
                }
            }
            .onAppear() {
                Task {
                    await handleOnLoad()
                }
            }
        }
    }

    @MainActor
    func handleOnLoad() async {
        let healthStorePermissions = await healthStoreManager.checkHealthKitPermissionsStatus()
        if healthStorePermissions == .shouldRequest {
            let result = await healthStoreManager.requestHealthKitPermissions()
            if result == .success {
                if let timeInSun = await sunWorker.getSunTime(for: Date()) {
                    self.timeInSun = timeInSun
                }
                watchUserInfo.timeInSun = timeInSun
                WidgetCenter.shared.reloadAllTimelines()
            }
        } else {
            if let timeInSun = await sunWorker.getSunTime(for: Date()) {
                self.timeInSun = timeInSun
                watchUserInfo.timeInSun = timeInSun
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    var sunflowerView: some View {
        VStack(alignment: .center) {
            Spacer()
            Text("🌻")
                .font(.system(size: 40))
            Spacer()
            VStack(alignment:. leading) {
                HStack {
                    Text("Time in SUN:")
                        .font(.footnote)
                    Spacer()
                    Text(timeInSun.hoursMinutes())
                        .font(.body)
                        .fontWeight(.bold)
                }
                HStack {
                    Text("Daily goal:")
                        .font(.footnote)
                    Spacer()
                    Text(watchUserInfo.sunGoal.hoursMinutes())
                        .font(.body)
                        .fontWeight(.bold)
                }

            }
            .foregroundStyle(AppColors.green.color)
            Spacer()
            if let lastPickedDate = watchUserInfo.lastPickedSunflowerDate,
               lastPickedDate.isSameDay(as: Date()) {
                Text("Your Sunflower is picked!")
                    .foregroundStyle(AppColors.green.color)
                    .font(.callout)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .multilineTextAlignment(.center)
            } else {
                if timeInSun >= watchUserInfo.sunGoal {
                    Button(action: {
                        Task {
                            await MainActor.run {
                                watchToAppManager.sendMessageToIphone(timeInSun: timeInSun)
                                watchUserInfo.lastPickedSunflowerDate = Date()
                            }
                        }
                    }) {
                        Text("PICK SUNFLOWER")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                        .foregroundStyle(AppColors.green.color)
                        .padding()
                }
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    }

    var lockedView: some View {
        VStack {
            Spacer()
            Text("🌻")
                .font(.system(size: 40))
            Text("Get Sunflower+ from your mobile app to access Watch features!")
                .foregroundStyle(AppColors.green.color)
                .font(.body)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView(timeInSun: 123)
}
