import SwiftUI
import SwiftData

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var title: String = ""
    @FocusState private var isFocused: Bool

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(.secondary.opacity(0.3))
                .frame(width: 48, height: 6)
                .padding(.top, 12)

            Text("Add to Inbox")
                .font(.headline)

            TextField("New task", text: $title)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit(addTask)

            Button(action: addTask) {
                Text("Add")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(.clear)
                            // Crystal clear Apple Liquid Glass for primary button
                            .glassEffect(
                                .clear
                                    .interactive(),
                                in: .capsule
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
                    )
                    .foregroundStyle(
                        Palette.color(for: "Calm")
                    )
                    .opacity(trimmedTitle.isEmpty ? 0.45 : 1)
            }
            .disabled(trimmedTitle.isEmpty)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.clear)
                // Authentic Apple Liquid Glass - clear variant for sheet background
                .glassEffect(
                    .clear.interactive(),
                    in: .rect(cornerRadius: 32)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(.white.opacity(0.15), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
        )
        .background(
            ZStack {
                AuroraBackground()
                    .blur(radius: 20)
                    .overlay(Color.black.opacity(0.35))
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.45)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        )
        .presentationDetents([.fraction(0.35)])
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isFocused = true
            }
        }
    }

    private func addTask() {
        let trimmed = trimmedTitle
        guard !trimmed.isEmpty else { return }

        var defaultCategory: Category?
        let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.sortOrder == 0 })
        if let fetched = try? context.fetch(descriptor) {
            defaultCategory = fetched.first
        }

        let task = Task(title: trimmed, category: defaultCategory)
        context.insert(task)

        do {
            try context.save()
            Haptic.play(.tapLight)
        } catch {
            assertionFailure("Failed to save quick add task: \(error.localizedDescription)")
        }

        title = ""
        dismiss()
    }
}

#Preview {
    let container = PreviewSampleData.container
    return QuickAddView()
        .modelContainer(container)
}
