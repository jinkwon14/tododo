import SwiftUI
import SwiftData
import UIKit

struct CategoryPushPopPicker: View {
    let categories: [Category]
    let anchorRect: CGRect
    let selectedCategoryID: UUID?
    let isUnassigned: Bool
    @Binding var dragLocation: CGPoint?
    var onSelection: (Category?) -> Void
    var onCancel: () -> Void

    @State private var isVisible = false
    @State private var highlightedCategoryID: UUID?
    @State private var isNoneHighlighted = false
    @State private var preparedHaptics = false

    private enum Constants {
        static let paletteRadius: CGFloat = 112
        static let itemDiameter: CGFloat = 56
        static let highlightThreshold: CGFloat = itemDiameter * 0.7
        static let noneThreshold: CGFloat = itemDiameter * 0.55
    }

    private let paletteRadius: CGFloat = Constants.paletteRadius
    private let itemSize: CGFloat = Constants.itemDiameter
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let impactFeedback = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dragLocation = nil
                        onCancel()
                    }

                palette
                    .position(x: anchorRect.midX, y: anchorRect.midY)
                    .scaleEffect(isVisible ? 1 : 0.85)
                    .opacity(isVisible ? 1 : 0)
                    .animation(.spring(response: 0.32, dampingFraction: 0.8), value: isVisible)
            }
        }
        .onAppear {
            prepareHapticsIfNeeded()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                impactFeedback.impactOccurred()
            }
        }
        .onDisappear {
            highlightedCategoryID = nil
            isNoneHighlighted = false
        }
        .onChange(of: dragLocation) { location in
            updateHighlight(for: location)
        }
        .onChange(of: categories.map(\.id)) { _ in
            updateHighlight(for: dragLocation)
        }
    }

    private var palette: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: paletteRadius * 2, height: paletteRadius * 2)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.28), radius: 18, x: 0, y: 12)

            ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                categoryButton(for: category, isHighlighted: highlightedCategoryID == category.id)
                    .offset(offset(for: index, total: categories.count))
            }

            noneButton

            if let pointer = dragLocation {
                Circle()
                    .strokeBorder(Color.white.opacity(0.26), lineWidth: 2)
                    .background(Circle().fill(Color.white.opacity(0.1)))
                    .frame(width: 32, height: 32)
                    .offset(x: pointer.x, y: pointer.y)
                    .opacity(0.8)
                    .animation(.easeOut(duration: 0.12), value: dragLocation)
            }
        }
    }

    private func categoryButton(for category: Category, isHighlighted: Bool) -> some View {
        let tint = Palette.color(for: category.colorID)
        let isSelected = selectedCategoryID == category.id
        return Button {
            dragLocation = nil
            onSelection(category)
        } label: {
            ZStack {
                Circle()
                    .fill(tint.opacity(isHighlighted ? 0.38 : 0.22))
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(tint)
            }
            .frame(width: itemSize, height: itemSize)
            .overlay(
                Circle()
                    .stroke(tint.opacity(isSelected ? 1 : 0.5), lineWidth: isSelected ? 2 : 1)
            )
            .overlay(
                Circle()
                    .stroke(tint.opacity(isHighlighted ? 0.8 : 0), lineWidth: isHighlighted ? 4 : 0)
                    .blur(radius: isHighlighted ? 1.5 : 0)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Assign to \(category.name)"))
        .scaleEffect(isHighlighted ? 1.08 : 1.0)
        .shadow(color: .black.opacity(isHighlighted ? 0.25 : 0.18), radius: isHighlighted ? 16 : 12, x: 0, y: isHighlighted ? 8 : 6)
        .animation(.spring(response: 0.25, dampingFraction: 0.82), value: isHighlighted)
        .overlay(alignment: .bottom) {
            if isHighlighted {
                Text(category.name)
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                    )
                    .offset(y: itemSize / 2 + 18)
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }

    private var noneButton: some View {
        let tint = Palette.color(for: nil)
        let isHighlighted = isNoneHighlighted
        return Button {
            dragLocation = nil
            onSelection(nil)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "circle.dashed")
                    .font(.title3)
                Text("None")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(width: itemSize + 12, height: itemSize + 12)
            .foregroundStyle((isUnassigned || isHighlighted) ? tint : .secondary)
            .background(
                Circle()
                    .fill(tint.opacity(isHighlighted ? 0.38 : 0.25))
            )
            .overlay(
                Circle()
                    .stroke(tint.opacity((isHighlighted || isUnassigned) ? 1 : 0.4), lineWidth: (isHighlighted || isUnassigned) ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Remove category"))
        .scaleEffect(isHighlighted ? 1.05 : 1.0)
        .shadow(color: .black.opacity(isHighlighted ? 0.24 : 0.16), radius: isHighlighted ? 16 : 10, x: 0, y: isHighlighted ? 8 : 4)
        .animation(.spring(response: 0.24, dampingFraction: 0.85), value: isHighlighted)
    }

    private func offset(for index: Int, total: Int) -> CGSize {
        Self.offset(for: index, total: total)
    }

    private func updateHighlight(for location: CGPoint?) {
        let previousCategoryID = highlightedCategoryID
        let previousNone = isNoneHighlighted

        if let location {
            if let result = Self.selection(for: location, categories: categories) {
                highlightedCategoryID = result.categoryID
                isNoneHighlighted = result.isNone
            } else {
                highlightedCategoryID = nil
                isNoneHighlighted = false
            }
        } else {
            highlightedCategoryID = nil
            isNoneHighlighted = false
        }

        if previousCategoryID != highlightedCategoryID || previousNone != isNoneHighlighted {
            selectionFeedback.selectionChanged()
        }
    }

    private func prepareHapticsIfNeeded() {
        guard !preparedHaptics else { return }
        selectionFeedback.prepare()
        impactFeedback.prepare()
        preparedHaptics = true
    }
}

#Preview {
    let sampleCategories = Palette.defaults.enumerated().map { index, preset in
        Category(name: preset.name, colorID: preset.colorID, icon: preset.icon, sortOrder: index)
    }
    return CategoryPushPopPicker(
        categories: sampleCategories,
        anchorRect: CGRect(x: 160, y: 320, width: 200, height: 80),
        selectedCategoryID: sampleCategories.first?.id,
        isUnassigned: false,
        dragLocation: .constant(nil),
        onSelection: { _ in },
        onCancel: {}
    )
    .modelContainer(PreviewSampleData.container)
}

extension CategoryPushPopPicker {
    struct DragSelection {
        let categoryID: UUID?
        let isNone: Bool
    }

    static func selection(for location: CGPoint, categories: [Category]) -> DragSelection? {
        let distanceFromCenter = hypot(location.x, location.y)
        if distanceFromCenter < Constants.noneThreshold {
            return DragSelection(categoryID: nil, isNone: true)
        }

        guard !categories.isEmpty else { return nil }

        let centers: [CGPoint] = (0..<categories.count).map { index in
            let offset = self.offset(for: index, total: categories.count)
            return CGPoint(x: offset.width, y: offset.height)
        }

        var closestIndex: Int?
        var closestDistance: CGFloat = .greatestFiniteMagnitude

        for (idx, center) in centers.enumerated() {
            let distance = hypot(location.x - center.x, location.y - center.y)
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = idx
            }
        }

        guard let index = closestIndex, closestDistance < Constants.highlightThreshold else {
            return nil
        }

        return DragSelection(categoryID: categories[index].id, isNone: false)
    }

    static func offset(for index: Int, total: Int) -> CGSize {
        guard total > 0 else { return .zero }
        let fraction = Double(index) / Double(total)
        let angle = fraction * (.pi * 2) - .pi / 2
        let radius = Constants.paletteRadius - Constants.itemDiameter * 0.7
        let x = cos(angle) * radius
        let y = sin(angle) * radius
        return CGSize(width: x, height: y)
    }
}
