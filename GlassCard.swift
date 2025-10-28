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
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.18),
                                tint.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    // Apple Liquid Glass UI with interactive modifier
                    .glassEffect(
                        .regular
                            .interactive()
                            .tint(tint.opacity(isPressed ? 0.4 : 0.25)),
                        in: .rect(cornerRadius: 24)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .shadow(color: tint.opacity(0.25), radius: 16, x: 0, y: 12)
            // Smooth liquid-like animations for state changes
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isPressed)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(tint.opacity(0.22))
                    .frame(height: 2)
                    .blur(radius: 6)
                    .offset(y: 12)
                    .opacity(0.7)
            }
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
