import SwiftUI

enum Destinations: Hashable {
    case field(number: Int)
}

struct DestinationView: View {
    let destination: Destinations

    var body: some View {
        switch destination {
        case let .field(numberOfSunflowers):
            return SunflowersField(numberOfSunflowers: numberOfSunflowers)
        }
    }
}

struct SunflowerTab: View {
    @State private var selectedTab: Int = 0

    init() {
        UITabBar.appearance().backgroundColor = AppColors.white.uiColor
        UITabBar.appearance().unselectedItemTintColor = AppColors.green.uiColor

    }

    var body: some View {
        TabView(selection: $selectedTab) {
            SunflowerView()
                .background(AppColors.backgroundLight.color)
                .tabItem {
                    if selectedTab == 0 {
                        Image("sunflowerSelected")
                    } else {
                        Image("sunflowerUnselected")
                    }
                    Text("SUNFLOWER")
                        .foregroundStyle(AppColors.green.color)
                }
                .tag(0)

            CalendarView()
                .background(AppColors.backgroundLight.color)
                .tabItem {
                    if selectedTab == 1 {
                        Image("calendarSelected")
                    } else {
                        Image("calendarUnselected")
                    }
                    Text("CALENDAR")
                        .foregroundStyle(AppColors.green.color)
                }
                .tag(1)

            SettingsView()
                .background(AppColors.backgroundLight.color)
                .tabItem {
                    if selectedTab == 2 {
                        Image("settingsSelected")
                    } else {
                        Image("settingsUnselected")
                    }
                    Text("SETTINGS")
                        .foregroundStyle(AppColors.green.color)
                }
                .tag(2)
        }
        .accentColor(AppColors.green.color)
    }
}

//extension SunflowerTab {
//    @MainActor static func prepareForPreview() -> some View {
//        let healthStoreManager = HealthStoreManager()
//        let sunWorker = SunWorker(healthManager: healthStoreManager)
//        let userInfo = UserInfo()
//        let subscriptionsManager = SubscriptionsManager(watchManager: WatchManager(), userInfo: userInfo)
//
//        return SunflowerTab()
//            .environmentObject(healthStoreManager)
//            .environmentObject(sunWorker)
//            .environmentObject(userInfo)
//            .environmentObject(subscriptionsManager)
//    }
//}
//
//#Preview {
//    SunflowerTab.prepareForPreview()
//}
