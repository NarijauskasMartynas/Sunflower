import WatchConnectivity

class WatchToAppManager: NSObject, ObservableObject {
    let session = WCSession.default
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
}

extension WatchToAppManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        //
    }

    func sendMessageToIphone(timeInSun: Double) {
        if session.isReachable {
            session.sendMessage(["timeInSun": timeInSun], replyHandler: nil)
        } else {
            print("Session unreachable")
        }
    }
}
