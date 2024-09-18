import SwiftUI

class UserInfo: ObservableObject {
    @AppStorage(DefaultKeys.sunGoal.rawValue, store: UserDefaults(suiteName: DefaultKeys.suite.rawValue))
    var sunGoal: Double = 30 * 60

    @AppStorage(DefaultKeys.gaveReview.rawValue, store: UserDefaults(suiteName: DefaultKeys.suite.rawValue))
    var gaveReview: Bool = false

    @AppStorage(DefaultKeys.launchCount.rawValue, store: UserDefaults(suiteName: DefaultKeys.suite.rawValue))
    var launchCount: Int = 0

    @AppStorage(DefaultKeys.launchLimit.rawValue, store: UserDefaults(suiteName: DefaultKeys.suite.rawValue))
    var nextAlertLaunchCount: Int = 2

    @AppStorage(DefaultKeys.lastSunNotificationDate.rawValue, store: UserDefaults(suiteName: DefaultKeys.suite.rawValue))
    private var lastSunNotificationDateString: String?

    var lastSunNotificationDate: Date? {
        get {
            if let lastSunNotificationDateString = lastSunNotificationDateString {
                return Date.fromISO8601String(lastSunNotificationDateString)
            }
            return nil
        }
        set {
            if let date = newValue {
                lastSunNotificationDateString = date.iso8601String
            } else {
                lastSunNotificationDateString = nil
            }
        }
    }

    @AppStorage(DefaultKeys.lastSleepNotificationDate.rawValue, store: UserDefaults(suiteName: DefaultKeys.suite.rawValue))
    private var lastSleepNotificationDateString: String?

    var lastSleepNotificationDate: Date? {
        get {
            if let lastSleepNotificationDateString = lastSleepNotificationDateString {
                return Date.fromISO8601String(lastSleepNotificationDateString)
            }
            return nil
        }
        set {
            if let date = newValue {
                lastSleepNotificationDateString = date.iso8601String
            } else {
                lastSleepNotificationDateString = nil
            }
        }
    }

    @AppStorage(DefaultKeys.lastPickedDate.rawValue, store: UserDefaults(suiteName: DefaultKeys.suite.rawValue))
    private var lastPickedDateString: String?

    var lastPickedDateValue: Date? {
        get {
            if let lastPickedDateString = lastPickedDateString {
                return Date.fromISO8601String(lastPickedDateString)
            }
            return nil
        }
        set {
            if let date = newValue {
                lastPickedDateString = date.iso8601String
            } else {
                lastPickedDateString = nil
            }
        }
    }

    @AppStorage(DefaultKeys.onboardingDate.rawValue, store: UserDefaults(suiteName: DefaultKeys.suite.rawValue))
    private var onboardingDateString: String?

    var onboardingDateValue: Date? {
        get {
            if let onboardingDateString = onboardingDateString {
                return Date.fromISO8601String(onboardingDateString)
            }
            return nil
        }
        set {
            if let date = newValue {
                onboardingDateString = date.iso8601String
            } else {
                onboardingDateString = nil
            }
        }
    }

    @AppStorage(DefaultKeys.promoOfferStartDate.rawValue, store: UserDefaults(suiteName: DefaultKeys.suite.rawValue))
    private var promoOfferStartDateString: String?

    var promoOfferStartDateValue: Date? {
        get {
            if let promoOfferStartDateString = promoOfferStartDateString {
                return Date.fromISO8601String(promoOfferStartDateString)
            }
            return nil
        }
        set {
            if let date = newValue {
                promoOfferStartDateString = date.iso8601String
            } else {
                promoOfferStartDateString = nil
            }
        }
    }

    @AppStorage(DefaultKeys.lastStreakLossShownDate.rawValue, store: UserDefaults(suiteName: DefaultKeys.suite.rawValue))
    private var lastStreakLossShownDateString: String?

    var lastStreakLossShownDate: Date? {
        get {
            if let promoOfferStartDateString = lastStreakLossShownDateString {
                return Date.fromISO8601String(promoOfferStartDateString)
            }
            return nil
        }
        set {
            if let date = newValue {
                lastStreakLossShownDateString = date.iso8601String
            } else {
                lastStreakLossShownDateString = nil
            }
        }
    }


    // WIDGET RELATED ONLY
    @AppStorage(DefaultKeys.timeInSun.rawValue, store: UserDefaults(suiteName: DefaultKeys.suite.rawValue))
    var timeInSun: Double = 0
}
