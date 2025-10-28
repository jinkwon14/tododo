import SwiftUI
import UniformTypeIdentifiers
import Foundation

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
            loadIDs(from: providers) { ids in
                guard !ids.isEmpty else { return }
                onDropIDs(ids)
                Haptic.play(.dropSuccess)
            }
            return true
        }
    }

    private func loadIDs(from providers: [NSItemProvider], completion: @escaping ([UUID]) -> Void) {
        let identifier = UTType.text.identifier
        let group = DispatchGroup()
        let lock = NSLock()
        var collected: [UUID] = []

        for provider in providers where provider.hasItemConformingToTypeIdentifier(identifier) {
            group.enter()
            provider.loadDataRepresentation(forTypeIdentifier: identifier) { data, _ in
                defer { group.leave() }

                guard
                    let data,
                    let string = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                    let uuid = UUID(uuidString: string)
                else {
                    return
                }

                lock.lock()
                collected.append(uuid)
                lock.unlock()
            }
        }

        group.notify(queue: .main) {
            completion(collected)
        }
    }
}
