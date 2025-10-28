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
            )
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
