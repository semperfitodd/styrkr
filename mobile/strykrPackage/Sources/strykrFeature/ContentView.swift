import SwiftUI

public struct ContentView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("STYRKR")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your Ultimate Strength Training Companion")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
