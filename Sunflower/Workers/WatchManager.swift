import WatchConnectivity
import SwiftData

@MainActor
class WatchManager: NSObject, ObservableObject {
    let modelContext: ModelContext
    var userInfo: UserInfo?
    let session = WCSession.default

    init(modelContainer: ModelContainer) {
        self.modelContext = modelContainer.mainContext
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    func sendLastPickedSunflowerDate(date: Date) {
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: date)
        let message: [String: Any] = ["lastSunflowerDate": dateString]
        session.transferCurrentComplicationUserInfo(message)
    }

    func sendSunGoal(sunGoal: Double) {
        session.transferCurrentComplicationUserInfo(["sunGoal": sunGoal])
    }

    func sendIsPro(isPro: Bool) {
        session.transferCurrentComplicationUserInfo(["isPro": isPro])
    }

    func sendTimeInSun(timeInSun: Double) {
        session.transferCurrentComplicationUserInfo(["timeInSun": timeInSun])
    }
}

extension WatchManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Session activation failed with error: \(error.localizedDescription)")
        } else {
            print("Session activated with state: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive if needed
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Handle session deactivation if needed
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Received message: \(message)")

        if let timeInSun = message["timeInSun"] as? NSNumber {
            Task {
                await MainActor.run {
                    let newDayData = DayData(date: Date())
                    modelContext.insert(newDayData)

                    userInfo?.lastPickedDateValue = Date()

                    do {
                        try modelContext.save()
                        print("Data saved successfully")
                    } catch {
                        Logger.shared.logError(error)
                    }
                }
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // Handle received message with reply handler
        print("Received message with reply: \(message)")
        replyHandler(["response" : "Message received"])
    }
}

