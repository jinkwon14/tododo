import SwiftUI
import UniformTypeIdentifiers
import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct BucketOrb: View {
    let category: Category
    let onDropIDs: ([UUID]) -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Palette.color(for: category.colorID).opacity(0.85),
                                Palette.color(for: category.colorID).opacity(0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .glassEffect(.regular.tint(Palette.color(for: category.colorID)), in: .circle)
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.22), lineWidth: 1)
                    )
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .blur(radius: 6)
                            .padding(4), alignment: .top
                    )
                CategoryIconView(icon: category.icon)
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

private struct CategoryIconView: View {
    let icon: String

    var body: some View {
        Group {
            if isSymbol(icon) {
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
            } else {
                Text(icon)
                    .font(.system(size: 32))
            }
        }
        .frame(width: 40, height: 40)
        .minimumScaleFactor(0.5)
        .accessibilityHidden(true)
    }

    private func isSymbol(_ name: String) -> Bool {
        #if canImport(UIKit)
        return UIImage(systemName: name) != nil
        #elseif canImport(AppKit)
        return NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
        #else
        return false
        #endif
    }
}
