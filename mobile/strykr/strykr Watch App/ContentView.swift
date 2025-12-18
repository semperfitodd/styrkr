import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Styrkr")
                .font(.headline)
            Text("Stories on your wrist")
                .font(.caption)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}