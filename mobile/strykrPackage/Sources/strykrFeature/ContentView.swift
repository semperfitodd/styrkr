import SwiftUI

public struct ContentView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Styrkr")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Interactive storytelling for children")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
