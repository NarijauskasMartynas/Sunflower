import SwiftUI

enum AppColors {
    case backgroundLight
    case orange
    case brown
    case green
    case white
    case red
    case blue
    case calendarGreen

    var color: Color {
        switch self {
        case .backgroundLight:
            return Color(hex: "#E5D9B3") 
        case .orange:
            return Color(hex: "#FFCA5F")
        case .brown:
            return Color(hex: "#C68413")  
        case .green:
            return Color(hex: "#345F55")
        case .white:
            return Color(hex: "#F2EAD0")
        case .red:
            return Color(hex: "#EBB5A3")
        case .blue:
            return Color(hex: "#C1D7D4")
        case .calendarGreen:
            return Color(hex: "#C5DDB4")
        }
    }

    var uiColor: UIColor {
        switch self {
        case .backgroundLight:
            return UIColor(hex: "#E5D9B3")
        case .orange:
            return UIColor(hex: "#FFCA5F")
        case .brown:
            return UIColor(hex: "#C68413")
        case .green:
            return UIColor(hex: "#345F55")
        case .white:
            return UIColor(hex: "#F2EAD0")
        case .red:
            return UIColor(hex: "#EBB5A3")
        case .blue:
            return UIColor(hex: "#C1D7D4") 
        case .calendarGreen:
            return UIColor(hex: "#C5DDB4")
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex.hasPrefix("#") ? String(hex.dropFirst()) : hex)
        var hexNumber: UInt64 = 0
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1

        if scanner.scanHexInt64(&hexNumber) {
            if hex.count == 7 {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat(hexNumber & 0x0000ff) / 255
            }
        } else {
            self.init(.sRGB, red: 1, green: 1, blue: 1, opacity: 0) // Fallback color
            return
        }

        self.init(.sRGB, red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex.hasPrefix("#") ? String(hex.dropFirst()) : hex)
        var hexNumber: UInt64 = 0
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1

        if scanner.scanHexInt64(&hexNumber) {
            if hex.count == 7 {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat(hexNumber & 0x0000ff) / 255
            }
        } else {
            self.init(red: 1, green: 1, blue: 1, alpha: 0) // Fallback color
            return
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
