import SwiftUI
import SwiftData

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var title: String = ""
    @FocusState private var isFocused: Bool

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
                            .fill(Palette.color(for: "Calm").opacity(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.3 : 0.8))
                    )
                    .foregroundStyle(.primary)
            }
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.clear)
                .glassEffect(.clear, in: .rect(cornerRadius: 32))
        )
        .presentationDetents([.fraction(0.35)])
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isFocused = true
            }
        }
    }

    private func addTask() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let task = Task(title: trimmed)
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
