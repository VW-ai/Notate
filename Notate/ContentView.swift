import SwiftUI

struct ContentView: View {
    @State private var lastCaptured: String = ""
    @State private var showToast = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Notate — POC")
                    .font(.title)
                Text("状态：\(showToast ? "已捕获" : "空闲")")
                Text("最近一次：\(lastCaptured)")
                    .lineLimit(2)
            }
            .padding()

            if showToast {
                Text("Captured: \(lastCaptured)")
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .notateDidFinishCapture)) { note in
            if let text = note.object as? String {
                lastCaptured = text
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { showToast = false }
                }
            }
        }
    }
}
