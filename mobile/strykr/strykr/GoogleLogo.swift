import SwiftUI

struct GoogleLogo: View {
    var size: CGFloat = 20
    
    var body: some View {
        ZStack {
            // Blue - top right
            Path { path in
                let scale = size / 24.0
                path.move(to: CGPoint(x: 22.56 * scale, y: 12.25 * scale))
                path.addCurve(to: CGPoint(x: 22.36 * scale, y: 10 * scale), 
                             control1: CGPoint(x: 22.56 * scale, y: 11.47 * scale), 
                             control2: CGPoint(x: 22.49 * scale, y: 10.72 * scale))
                path.addLine(to: CGPoint(x: 12 * scale, y: 10 * scale))
                path.addLine(to: CGPoint(x: 12 * scale, y: 14.26 * scale))
                path.addLine(to: CGPoint(x: 17.92 * scale, y: 14.26 * scale))
                path.addCurve(to: CGPoint(x: 15.71 * scale, y: 17.57 * scale), 
                             control1: CGPoint(x: 17.66 * scale, y: 15.63 * scale), 
                             control2: CGPoint(x: 16.88 * scale, y: 16.79 * scale))
                path.addLine(to: CGPoint(x: 15.71 * scale, y: 20.34 * scale))
                path.addLine(to: CGPoint(x: 19.28 * scale, y: 20.34 * scale))
                path.addCurve(to: CGPoint(x: 22.56 * scale, y: 12.25 * scale), 
                             control1: CGPoint(x: 21.36 * scale, y: 18.42 * scale), 
                             control2: CGPoint(x: 22.56 * scale, y: 15.6 * scale))
                path.closeSubpath()
            }
            .fill(Color(red: 0.259, green: 0.522, blue: 0.957))
            
            // Green - bottom right
            Path { path in
                let scale = size / 24.0
                path.move(to: CGPoint(x: 12 * scale, y: 23 * scale))
                path.addCurve(to: CGPoint(x: 19.28 * scale, y: 20.34 * scale), 
                             control1: CGPoint(x: 14.97 * scale, y: 23 * scale), 
                             control2: CGPoint(x: 17.46 * scale, y: 22.02 * scale))
                path.addLine(to: CGPoint(x: 15.71 * scale, y: 17.57 * scale))
                path.addCurve(to: CGPoint(x: 9.55 * scale, y: 13.04 * scale), 
                             control1: CGPoint(x: 14.73 * scale, y: 18.23 * scale), 
                             control2: CGPoint(x: 12.48 * scale, y: 16.64 * scale))
                path.addLine(to: CGPoint(x: 2.18 * scale, y: 15.88 * scale))
                path.addCurve(to: CGPoint(x: 12 * scale, y: 23 * scale), 
                             control1: CGPoint(x: 3.99 * scale, y: 20.53 * scale), 
                             control2: CGPoint(x: 7.7 * scale, y: 23 * scale))
                path.closeSubpath()
            }
            .fill(Color(red: 0.204, green: 0.659, blue: 0.325))
            
            // Yellow - bottom left
            Path { path in
                let scale = size / 24.0
                path.move(to: CGPoint(x: 5.84 * scale, y: 14.09 * scale))
                path.addCurve(to: CGPoint(x: 5.49 * scale, y: 12 * scale), 
                             control1: CGPoint(x: 5.62 * scale, y: 13.43 * scale), 
                             control2: CGPoint(x: 5.49 * scale, y: 12.73 * scale))
                path.addCurve(to: CGPoint(x: 5.84 * scale, y: 9.91 * scale), 
                             control1: CGPoint(x: 5.49 * scale, y: 11.27 * scale), 
                             control2: CGPoint(x: 5.62 * scale, y: 10.57 * scale))
                path.addLine(to: CGPoint(x: 5.84 * scale, y: 7.07 * scale))
                path.addLine(to: CGPoint(x: 2.18 * scale, y: 7.07 * scale))
                path.addCurve(to: CGPoint(x: 1 * scale, y: 12 * scale), 
                             control1: CGPoint(x: 1.43 * scale, y: 8.55 * scale), 
                             control2: CGPoint(x: 1 * scale, y: 10.22 * scale))
                path.addCurve(to: CGPoint(x: 2.18 * scale, y: 16.93 * scale), 
                             control1: CGPoint(x: 1 * scale, y: 13.78 * scale), 
                             control2: CGPoint(x: 1.43 * scale, y: 15.45 * scale))
                path.addLine(to: CGPoint(x: 5.03 * scale, y: 14.71 * scale))
                path.addLine(to: CGPoint(x: 5.84 * scale, y: 14.09 * scale))
                path.closeSubpath()
            }
            .fill(Color(red: 0.984, green: 0.737, blue: 0.020))
            
            // Red - top left
            Path { path in
                let scale = size / 24.0
                path.move(to: CGPoint(x: 12 * scale, y: 5.38 * scale))
                path.addCurve(to: CGPoint(x: 16.21 * scale, y: 7.02 * scale), 
                             control1: CGPoint(x: 13.62 * scale, y: 5.38 * scale), 
                             control2: CGPoint(x: 15.06 * scale, y: 5.94 * scale))
                path.addLine(to: CGPoint(x: 19.36 * scale, y: 3.87 * scale))
                path.addCurve(to: CGPoint(x: 12 * scale, y: 1 * scale), 
                             control1: CGPoint(x: 17.45 * scale, y: 2.09 * scale), 
                             control2: CGPoint(x: 14.97 * scale, y: 1 * scale))
                path.addCurve(to: CGPoint(x: 2.18 * scale, y: 7.07 * scale), 
                             control1: CGPoint(x: 7.7 * scale, y: 1 * scale), 
                             control2: CGPoint(x: 3.99 * scale, y: 3.47 * scale))
                path.addLine(to: CGPoint(x: 5.84 * scale, y: 9.91 * scale))
                path.addCurve(to: CGPoint(x: 12 * scale, y: 5.38 * scale), 
                             control1: CGPoint(x: 6.71 * scale, y: 7.31 * scale), 
                             control2: CGPoint(x: 9.14 * scale, y: 5.38 * scale))
                path.closeSubpath()
            }
            .fill(Color(red: 0.918, green: 0.263, blue: 0.208))
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            GoogleLogo(size: 16)
            GoogleLogo(size: 20)
            GoogleLogo(size: 24)
        }
        
        Button(action: {}) {
            HStack {
                GoogleLogo(size: 20)
                Text("Continue with Google")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(12)
        }
        .padding()
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}

