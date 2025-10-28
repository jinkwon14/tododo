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
    @State private var isGlowing = false

    private var tint: Color {
        Palette.color(for: category.colorID)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(.clear)
                    .frame(width: 72, height: 72)
                    // Crystal clear Apple Liquid Glass bubble
                    .glassEffect(
                        .clear
                            .interactive(),
                        in: .circle
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.22), lineWidth: 0.6)
                            .blendMode(.plusLighter)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(isGlowing ? 0.5 : 0), lineWidth: 1.4)
                            .blur(radius: isGlowing ? 6 : 12)
                            .opacity(isGlowing ? 1 : 0)
                    )
                CategoryIconView(icon: category.icon, tint: tint)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1.5)
            }
            .scaleEffect(isHovering ? 1.08 : 1.0)
            // Smooth liquid-like animations for all state changes
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isHovering)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isGlowing)
            .animation(.easeInOut(duration: 0.3), value: category.tasks.count)
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

                // Trigger glow animation when task is dropped
                withAnimation(.easeIn(duration: 0.2)) {
                    isGlowing = true
                }
                // Return to normal state with a smooth fade
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        isGlowing = false
                    }
                }
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
    let tint: Color

    var body: some View {
        Group {
            if isSymbol(icon) {
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(tint)
            } else {
                Text(icon)
                    .font(.system(size: 32))
                    .foregroundStyle(tint)
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
