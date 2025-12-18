import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Styrkr")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Interactive storytelling for children")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    ContentView()
}
