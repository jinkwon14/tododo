import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct InboxView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Task> { !$0.isDone }, sort: [SortDescriptor(\.createdAt, order: .reverse)])
    private var tasks: [Task]
    @Query(sort: [SortDescriptor(\Category.sortOrder)]) private var categories: [Category]
    @State private var isAddPresented = false
    @State private var isAddCategoryPresented = false
    @State private var pendingCategoryID: UUID?

    init() {}

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    if tasks.isEmpty {
                        emptyState
                    } else {
                        ForEach(tasks) { task in
                            taskRow(task)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deleteTasks)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(scenicBackground)
                .safeAreaPadding(.bottom, 120)
                .refreshable {
                    await MainActor.run {
                        showAdd()
                    }
                }
                .navigationTitle("Inbox")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: showAdd) {
                            Image(systemName: "plus")
                                .font(.title3.weight(.semibold))
                        }
                        .accessibilityLabel("Add task")
                    }
                }

                bottomTray
                floatingAddButton
            }
        }
        .sheet(isPresented: $isAddPresented) {
            QuickAddView()
                .presentationBackground(.clear)
        }
        .sheet(isPresented: $isAddCategoryPresented) {
            NewCategoryView(onSave: { category in
                pendingCategoryID = category.id
            })
            .presentationBackground(.thinMaterial)
        }
        .onAppear(perform: ensureDefaultCategories)
    }

    private func showAdd() {
        Haptic.play(.tapLight)
        isAddPresented = true
    }

    private func deleteTasks(at offsets: IndexSet) {
        offsets.map { tasks[$0] }.forEach(context.delete)
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to delete tasks: \(error.localizedDescription)")
        }
    }

    private func taskRow(_ task: Task) -> some View {
        let tint = Palette.color(for: task.category?.colorID)
        return GlassCard(tint: tint) {
            HStack(alignment: .center, spacing: 16) {
                Button {
                    toggle(task)
                } label: {
                    Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(task.isDone ? .green : .secondary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(task.isDone ? "Mark incomplete" : "Mark complete")

                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    if let notes = task.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    if let due = task.due {
                        Label {
                            Text(due, style: .date)
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 12)
                if let category = task.category {
                    Label(category.name, systemImage: category.icon)
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onDrag {
            Haptic.play(.tapLight)
            return NSItemProvider(object: task.id.uuidString as NSString)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(task.title))
    }

    private var scenicBackground: some View {
        ZStack {
            Image("AuroraScenic")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [Color.black.opacity(0.35), Color.black.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 6)
            LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.15, blue: 0.2).opacity(0.9),
                    Color(red: 0.03, green: 0.05, blue: 0.09).opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .blendMode(.softLight)
            .overlay(
                RadialGradient(
                    colors: [Color.white.opacity(0.18), .clear],
                    center: .topLeading,
                    startRadius: 40,
                    endRadius: 420
                )
                .ignoresSafeArea()
            )
        }
    }

    private var floatingAddButton: some View {
        Button(action: showAdd) {
            Label("Add", systemImage: "plus")
                .labelStyle(.iconOnly)
                .font(.title2.weight(.bold))
                .padding()
                .background(
                    Circle()
                        .fill(.clear)
                        // Authentic Apple Liquid Glass for floating action button
                        .glassEffect(
                            .regular
                                .interactive()
                                .tint(Palette.color(for: "Calm").opacity(0.18)),
                            in: .circle
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                        )
                        .shadow(color: Palette.color(for: "Calm").opacity(0.25), radius: 16, x: 0, y: 8)
                )
        }
        .buttonStyle(.plain)
        .padding(.trailing, 24)
        .padding(.bottom, 140)
        .accessibilityLabel("Add task")
    }

    private var bottomTray: some View {
        VStack {
            Spacer()
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(.clear)
                .frame(height: 112)
                // Authentic Apple Liquid Glass for bottom tray
                .glassEffect(
                    .regular.interactive(),
                    in: .rect(cornerRadius: 36)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.3), radius: 28, x: 0, y: 14)
                .overlay(alignment: .center) {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories) { category in
                                    BucketOrb(category: category, onDropIDs: { ids in
                                        assign(ids: ids, to: category)
                                    })
                                    .id(category.id)
                                }
                                Button {
                                    isAddCategoryPresented = true
                                } label: {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                .fill(.clear)
                                                .frame(width: 72, height: 72)
                                                // Authentic Apple Liquid Glass for new category button
                                                .glassEffect(
                                                    .regular.interactive(),
                                                    in: .rect(cornerRadius: 24)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                        .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
                                                )
                                                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 8)
                                            Image(systemName: "plus")
                                                .font(.title2.weight(.semibold))
                                                .foregroundStyle(.white)
                                        }
                                        Text("New")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 12)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 24)
                        }
                        .onChange(of: categories.map(\.id)) { _ in
                            guard let target = pendingCategoryID else { return }
                            DispatchQueue.main.async {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    proxy.scrollTo(target, anchor: .center)
                                }
                                pendingCategoryID = nil
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            Text("Inbox is clear")
                .font(.headline)
            Text("Pull down or tap the plus to add a gentle reminder.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 80)
        .frame(maxWidth: .infinity)
    }

    private func toggle(_ task: Task) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            task.isDone.toggle()
            task.completedAt = task.isDone ? .now : nil
        }
        Haptic.play(.completeSuccess)
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save task toggle: \(error.localizedDescription)")
        }
    }

    private func assign(ids: [UUID], to category: Category) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            ids.forEach { id in
                if let task = tasks.first(where: { $0.id == id }) {
                    task.category = category
                } else {
                    if let fetched = try? context.fetch(FetchDescriptor<Task>(predicate: #Predicate { $0.id == id })) {
                        fetched.first?.category = category
                    }
                }
            }
        }
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save task assignment: \(error.localizedDescription)")
        }
    }

    private func ensureDefaultCategories() {
        guard categories.isEmpty else { return }
        Palette.defaults.enumerated().forEach { index, preset in
            let category = Category(name: preset.name, colorID: preset.colorID, icon: preset.icon, sortOrder: index)
            context.insert(category)
        }
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to seed default categories: \(error.localizedDescription)")
        }
    }
}

#Preview {
    InboxView()
        .modelContainer(PreviewSampleData.container)
}
