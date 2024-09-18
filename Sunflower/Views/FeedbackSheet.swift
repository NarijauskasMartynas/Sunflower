import SwiftUI
import FirebaseFirestore

struct FeedbackSheet: View {
    let onClose: () -> Void
    @State private var feedback: String = ""
    @State private var email: String = ""
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack {
            navigationBar
            VStack(alignment: .leading) {
                Text("Your feedback help us to grow.\nLet us know what can we do better!")
                    .font(.title3)
                    .foregroundStyle(AppColors.green.color)
                TextField(
                    "Your feedback",
                    text: $email,
                    prompt: Text("Enter your email")
                        .foregroundColor(AppColors.green.color),
                    axis: .vertical
                )
                .keyboardType(.emailAddress)
                .padding()
                .background(AppColors.white.color)
                .cornerRadius(10)
                .foregroundColor(AppColors.green.color)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppColors.green.color, lineWidth: 0.5)
                )
                .lineLimit(2)
                TextField(
                    "Your feedback",
                    text: $feedback,
                    prompt: Text("Enter your feedback ❤️")
                        .foregroundColor(AppColors.green.color),
                    axis: .vertical
                )
                .padding()
                .background(AppColors.white.color)
                .cornerRadius(10)
                .foregroundColor(AppColors.green.color)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColors.green.color, lineWidth: 0.5)
                )
                .lineLimit(20)

            }
            .padding(.horizontal, 10)
            Spacer()
            Button(action: {
                submitFeedback()
            }) {
                Text("SUBMIT")
                    .frame(width: UIScreen.main.bounds.width * 0.5)
            }

//            .frame(width: 280)
            .padding(10)

            .buttonStyle(PrimaryButtonStyle())
            .disabled(email == "" && feedback == "")
        }
        .background(AppColors.backgroundLight.color)
        .presentationDragIndicator(.hidden)
    }

    var navigationBar: some View {
        HStack {
            Spacer()
            Button(action: {
                onClose()
            }) {
                Image(systemName: "xmark")
                    .padding()
                    .clipShape(Circle())
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppColors.green.color)
            }
        }
    }

    func submitFeedback() {
        appState.showLoader = true
        let db = Firestore.firestore()
        let feedbackData: [String: Any] = [
            "feedback": feedback,
            "email" : email,
            "date" : Date()
        ]

        db.collection("feedbacks").addDocument(data: feedbackData) { error in
            appState.showLoader = false
            onClose()
            if let error = error {
                Logger.shared.logError(error)
            }
        }
    }
}

#Preview {
    FeedbackSheet(
        onClose: {}
    )
}
