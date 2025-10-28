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
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Palette.color(for: "Calm").opacity(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.25 : 0.95),
                                        Palette.color(for: "Calm").opacity(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.2 : 0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Palette.color(for: "Calm").opacity(0.35), radius: 16, x: 0, y: 10)
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
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 18)
        )
        .background(
            ZStack {
                Image("AuroraScenic")
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 18)
                    .overlay(Color.black.opacity(0.45))
                    .ignoresSafeArea()
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
