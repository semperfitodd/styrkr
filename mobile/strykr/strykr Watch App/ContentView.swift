import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.largeTitle)
                .foregroundColor(.accentColor)
            
            Text("STYRKR")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Track Your Strength")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}