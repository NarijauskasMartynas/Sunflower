import Foundation
import SwiftUI

extension Double {
    func hoursMinutesVertical() -> String {
        if !self.isFinite || self.isNaN {
            return "Invalid Duration"
        }

        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h\n\(minutes)m"
        } else if minutes > 0 {
            return "\n\(minutes)m"
        } else {
            return "0m"
        }
    }
    func hoursMinutes() -> String {
        if !self.isFinite || self.isNaN {
            return "Invalid Duration"
        }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated

        if let formattedString = formatter.string(from: TimeInterval(self)) {
            return formattedString
        } else {
            return "0 min"
        }
    }

    func hoursMinutesSeconds() -> String {
        if !self.isFinite || self.isNaN {
            return "Invalid Duration"
        }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated

        if let formattedString = formatter.string(from: TimeInterval(self)) {
            return formattedString
        } else {
            return "0 min"
        }
    }

    func onlyMinutes() -> String {
        if !self.isFinite || self.isNaN {
            return "Invalid Duration"
        }
        
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        
        return "\(minutes)"
    }
}
