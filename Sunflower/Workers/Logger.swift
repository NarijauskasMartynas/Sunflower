import FirebaseCrashlytics

class Logger {
    static let shared = Logger()

    private init() {}

    func logError(_ error: Error) {
#if DEBUG
        print(error)
#else
        Crashlytics.crashlytics().record(error: error)
#endif
    }

    func logMessage(_ message: String) {
#if DEBUG
        print(message)
#else
        Crashlytics.crashlytics().log(message)
#endif
    }
}
