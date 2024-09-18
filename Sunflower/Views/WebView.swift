import SwiftUI
import WebKit

struct WebView : View {
    let urlString: String
    let onClose: () -> Void

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        onClose()
                    }) {
                        Image(systemName: "xmark")
                            .padding()
                            .clipShape(Circle())
                            .foregroundColor(AppColors.green.color)
                    }
                }
                // Add the WKWebView
                WebViewRepresentable(urlString: urlString)
                    .edgesIgnoringSafeArea(.all)
            }
        }.background(AppColors.backgroundLight.color)
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
}

#Preview {
    WebView(urlString: "www.google.com") {
    }
}
