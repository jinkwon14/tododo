import SwiftUI

struct GlassCard<Content: View>: View {
    var tint: Color
    @ViewBuilder var content: Content

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
                    .fill(.clear)
                    .glassEffect(.regular.tint(tint), in: .rect(cornerRadius: 24))
<<<<<<< HEAD
                    .overlay(
                        LinearGradient(
                            colors: [Color.white.opacity(0.35), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blendMode(.screen)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .shadow(color: tint.opacity(0.3), radius: 18, x: 0, y: 14)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(tint.opacity(0.18))
                    .frame(height: 2)
                    .blur(radius: 6)
                    .offset(y: 12)
                    .opacity(0.6)
            }
=======
            )
>>>>>>> bdcba1a (Initialize HealingTodoApp Xcode project with Liquid Glass UI)
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
