import SwiftUI
import SwiftData

struct CategoryPushPopPicker: View {
    let categories: [Category]
    let anchorRect: CGRect
    let selectedCategoryID: UUID?
    let isUnassigned: Bool
    var onSelection: (Category?) -> Void
    var onCancel: () -> Void

    @State private var isVisible = false

    private let paletteRadius: CGFloat = 112
    private let itemSize: CGFloat = 56

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
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
            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                isVisible = true
            }
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
                categoryButton(for: category)
                    .offset(offset(for: index, total: categories.count))
            }

            noneButton
        }
    }

    private func categoryButton(for category: Category) -> some View {
        let tint = Palette.color(for: category.colorID)
        let isSelected = selectedCategoryID == category.id
        return Button {
            onSelection(category)
        } label: {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: itemSize, height: itemSize)
                .background(
                    Circle()
                        .fill(tint.opacity(0.22))
                )
                .overlay(
                    Circle()
                        .stroke(tint.opacity(isSelected ? 1 : 0.5), lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Assign to \(category.name)"))
    }

    private var noneButton: some View {
        let tint = Palette.color(for: nil)
        return Button {
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
            .foregroundStyle(isUnassigned ? tint : .secondary)
            .background(
                Circle()
                    .fill(tint.opacity(0.25))
            )
            .overlay(
                Circle()
                    .stroke(tint.opacity(isUnassigned ? 1 : 0.4), lineWidth: isUnassigned ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Remove category"))
    }

    private func offset(for index: Int, total: Int) -> CGSize {
        guard total > 0 else { return .zero }
        let fraction = Double(index) / Double(total)
        let angle = fraction * (.pi * 2) - .pi / 2
        let radius = paletteRadius - itemSize * 0.7
        let x = cos(angle) * radius
        let y = sin(angle) * radius
        return CGSize(width: x, height: y)
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
        onSelection: { _ in },
        onCancel: {}
    )
    .modelContainer(PreviewSampleData.container)
}
