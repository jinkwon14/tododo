import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct InboxView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Task> { !$0.isDone }, sort: [SortDescriptor(\.createdAt, order: .reverse)])
    private var tasks: [Task]
    @Query(sort: [SortDescriptor(\Category.sortOrder)]) private var categories: [Category]
    @State private var isAddPresented = false
<<<<<<< HEAD
    @State private var isAddCategoryPresented = false
    @State private var pendingCategoryID: UUID?
=======
>>>>>>> bdcba1a (Initialize HealingTodoApp Xcode project with Liquid Glass UI)

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
<<<<<<< HEAD
                .background(scenicBackground)
=======
                .background(gradientBackground)
>>>>>>> bdcba1a (Initialize HealingTodoApp Xcode project with Liquid Glass UI)
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
<<<<<<< HEAD
        .sheet(isPresented: $isAddCategoryPresented) {
            NewCategoryView(onSave: { category in
                pendingCategoryID = category.id
            })
            .presentationBackground(.thinMaterial)
        }
=======
>>>>>>> bdcba1a (Initialize HealingTodoApp Xcode project with Liquid Glass UI)
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

<<<<<<< HEAD
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
=======
    private var gradientBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.1, blue: 0.15),
                Color(red: 0.12, green: 0.18, blue: 0.24),
                Color(red: 0.08, green: 0.16, blue: 0.18)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
>>>>>>> bdcba1a (Initialize HealingTodoApp Xcode project with Liquid Glass UI)
    }

    private var floatingAddButton: some View {
        Button(action: showAdd) {
            Label("Add", systemImage: "plus")
                .labelStyle(.iconOnly)
                .font(.title2.weight(.bold))
                .padding()
                .background(
                    Circle()
<<<<<<< HEAD
                        .fill(
                            RadialGradient(
                                colors: [Palette.color(for: "Calm").opacity(0.85), Palette.color(for: "Calm").opacity(0.45)],
                                center: .center,
                                startRadius: 4,
                                endRadius: 48
                            )
                        )
                        .shadow(color: Palette.color(for: "Calm").opacity(0.3), radius: 18, x: 0, y: 10)
=======
                        .fill(Palette.color(for: "Calm").opacity(0.8))
                        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 8)
>>>>>>> bdcba1a (Initialize HealingTodoApp Xcode project with Liquid Glass UI)
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
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
<<<<<<< HEAD
                        .strokeBorder(.white.opacity(0.18), lineWidth: 1.2)
=======
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
>>>>>>> bdcba1a (Initialize HealingTodoApp Xcode project with Liquid Glass UI)
                )
                .background(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .fill(.clear)
                        .glassEffect(.regular, in: .rect(cornerRadius: 36))
<<<<<<< HEAD
                        .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 18)
                )
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
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.white.opacity(0.28), Color.white.opacity(0.05)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 72, height: 72)
                                                .glassEffect(.regular, in: .rect(cornerRadius: 24))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                                                )
                                                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 10)
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
=======
                )
                .overlay(alignment: .center) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(categories) { category in
                                BucketOrb(category: category, onDropIDs: { ids in
                                    assign(ids: ids, to: category)
                                })
                            }
                        }
                        .padding(.horizontal, 24)
>>>>>>> bdcba1a (Initialize HealingTodoApp Xcode project with Liquid Glass UI)
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
