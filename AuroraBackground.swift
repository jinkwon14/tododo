import SwiftUI

struct AuroraBackground: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.09, blue: 0.16),
                        Color(red: 0.02, green: 0.03, blue: 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        Color(red: 0.22, green: 0.62, blue: 0.98),
                        Color(red: 0.05, green: 0.23, blue: 0.52).opacity(0.2)
                    ],
                    center: UnitPoint(x: 0.2, y: 0.15),
                    startRadius: 0,
                    endRadius: size.width
                )
                .blendMode(.screen)

                RadialGradient(
                    colors: [
                        Color(red: 0.9, green: 0.45, blue: 0.78),
                        Color(red: 0.4, green: 0.05, blue: 0.45).opacity(0.15)
                    ],
                    center: UnitPoint(x: 0.75, y: 0.1),
                    startRadius: 0,
                    endRadius: size.width * 0.8
                )
                .blendMode(.screen)

                RadialGradient(
                    colors: [
                        Color(red: 0.36, green: 0.93, blue: 0.68),
                        Color(red: 0.02, green: 0.4, blue: 0.36).opacity(0.15)
                    ],
                    center: UnitPoint(x: 0.8, y: 0.75),
                    startRadius: 0,
                    endRadius: size.width * 0.9
                )
                .blendMode(.screen)

                Canvas { context, canvasSize in
                    let shapes: [(Color, CGRect, CGFloat)] = [
                        (Color(red: 0.31, green: 0.85, blue: 0.92).opacity(0.45), CGRect(x: -canvasSize.width * 0.25, y: canvasSize.height * 0.25, width: canvasSize.width * 1.3, height: canvasSize.width), 120),
                        (Color(red: 0.95, green: 0.66, blue: 0.31).opacity(0.35), CGRect(x: canvasSize.width * 0.35, y: -canvasSize.height * 0.4, width: canvasSize.width, height: canvasSize.width * 1.1), 140),
                        (Color(red: 0.56, green: 0.41, blue: 0.96).opacity(0.4), CGRect(x: canvasSize.width * 0.1, y: canvasSize.height * 0.55, width: canvasSize.width * 1.1, height: canvasSize.width * 0.9), 160)
                    ]

                    for (color, rect, blur) in shapes {
                        context.drawLayer { layer in
                            layer.addFilter(.blur(radius: blur))
                            layer.fill(Path(ellipseIn: rect), with: .color(color))
                        }
                    }
                }
                .opacity(0.9)

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
                        Color.black.opacity(0.35)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
            .drawingGroup()
        }
    }
}

#Preview {
    AuroraBackground()
}
