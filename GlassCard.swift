import SwiftUI

struct GlassCard<Content: View>: View {
    var tint: Color
    @ViewBuilder var content: Content

    @State private var isPressed = false

    init(tint: Color, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tint(tint)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.clear)
                    // Crystal clear Apple Liquid Glass card surface
                    .glassEffect(
                        .clear
                            .interactive(),
                        in: .rect(cornerRadius: 24)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(
                                .linearGradient(
                                    colors: [
                                        Color.white.opacity(0.55),
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.75
                            )
                            .blendMode(.plusLighter)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            // Smooth liquid-like animations for state changes
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isPressed)
    }
}

#Preview {
    GlassCard(tint: Palette.color(for: "Calm")) {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview Task")
                .font(.headline)
            Text("This is a glass card preview.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    .padding()
    .background(Color.black)
}
