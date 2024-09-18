import SwiftUI

struct LegendItem: View {
    let color: Color
    let text: String
    let emoji: String

    var body: some View {
        HStack {
            ZStack() {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: 30, height: 30)
                Text(emoji)
            }
            Text(" - \(text)")
        }
    }
}
