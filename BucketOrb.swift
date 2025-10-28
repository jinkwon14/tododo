import SwiftUI
import UniformTypeIdentifiers

struct BucketOrb: View {
    let category: Category
    let onDropIDs: ([UUID]) -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(.clear)
                    .frame(width: 68, height: 68)
                    .glassEffect(.regular.tint(Palette.color(for: category.colorID)), in: .circle)
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                    )
                Image(systemName: category.icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            }
            .scaleEffect(isHovering ? 1.08 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isHovering)
            .accessibilityLabel(Text("Drop into \(category.name)"))
            Text(category.name)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .onDrop(of: [.text], isTargeted: $isHovering) { providers in
            Swift.Task { @MainActor in
                let ids = await extractIDs(from: providers)
                guard !ids.isEmpty else { return }
                onDropIDs(ids)
                Haptic.play(.dropSuccess)
            }
            return true
        }
    }

    private func extractIDs(from providers: [NSItemProvider]) async -> [UUID] {
        await withTaskGroup(of: UUID?.self) { group in
            for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                group.addTask {
                    do {
                        let data = try await provider.loadDataRepresentation(forTypeIdentifier: UTType.text.identifier)
                        let string = String(data: data, encoding: .utf8)
                        return string.flatMap { UUID(uuidString: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                    } catch {
                        return nil
                    }
                }
            }

            var results: [UUID] = []
            for await value in group {
                if let value {
                    results.append(value)
                }
            }
            return results
        }
    }
}
