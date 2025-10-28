import SwiftUI
import SwiftData

struct NewCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name: String = ""
    @State private var emoji: String = "🌿"
    @State private var color: Color = Color(red: 0.45, green: 0.78, blue: 0.82)
    @FocusState private var isNameFocused: Bool

    var onSave: (Category) -> Void

    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(.white.opacity(0.25))
                .frame(width: 48, height: 6)
                .padding(.top, 12)

            VStack(spacing: 12) {
                Text("Create Category")
                    .font(.title2.weight(.semibold))
                Text("Craft a new space with your own emoji and color palette.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    TextField("Morning rituals", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Emoji")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    TextField("🌿", text: $emoji)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: emoji) { newValue in
                            guard !newValue.isEmpty else { return }
                            if let last = newValue.last {
                                emoji = String(last)
                            }
                        }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Color")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack {
                        Circle()
                            .fill(color)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                            )
                            .shadow(color: color.opacity(0.35), radius: 16, x: 0, y: 10)
                        ColorPicker("Choose", selection: $color, supportsOpacity: false)
                            .labelsHidden()
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.clear)
                    // Authentic Apple Liquid Glass for form container
                    .glassEffect(
                        .regular.interactive(),
                        in: .rect(cornerRadius: 28)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(.white.opacity(0.15), lineWidth: 0.5)
                    )
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button(action: save) {
                Text("Save Category")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.clear)
                            // Authentic Apple Liquid Glass for save button
                            .glassEffect(
                                .regular
                                    .interactive()
                                    .tint(color.opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.08 : 0.22)),
                                in: .rect(cornerRadius: 20)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                            )
                            .shadow(color: color.opacity(0.3), radius: 12, x: 0, y: 8)
                    )
                    .foregroundStyle(.primary)
            }
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button("Cancel", role: .cancel, action: dismiss.callAsFunction)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                AuroraBackground()
                    .blur(radius: 16)
                    .overlay(Color.black.opacity(0.25))
                LinearGradient(
                    colors: [Color.black.opacity(0.6), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        )
        .presentationDetents([.medium, .large])
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isNameFocused = true
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard let hex = color.hexString() else {
            errorMessage = "Unable to read selected color. Try again."
            return
        }
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\Category.sortOrder, order: .reverse)])
        let nextOrder: Int
        if let current = try? context.fetch(descriptor).first {
            nextOrder = current.sortOrder + 1
        } else {
            nextOrder = categoriesCount()
        }
        let category = Category(name: trimmedName, colorID: hex, icon: emoji, sortOrder: nextOrder)
        context.insert(category)
        do {
            try context.save()
            Haptic.play(.tapLight)
            onSave(category)
            dismiss()
        } catch {
            errorMessage = "Something went wrong saving the category. Please try again."
        }
    }

    private func categoriesCount() -> Int {
        (try? context.fetch(FetchDescriptor<Category>()).count) ?? 0
    }
}

#Preview {
    NewCategoryView { _ in }
        .modelContainer(PreviewSampleData.container)
}
