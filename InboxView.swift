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
    @State private var activePushPopTaskID: UUID?
    @State private var pickerAnchor: CGRect?
    @State private var rowFrames: [UUID: CGRect] = [:]
    @State private var categoryButtonFrames: [UUID: CGRect] = [:]
    @State private var pushPopDragLocation: CGPoint?
    @State private var skipNextTapTaskID: UUID?

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
                .safeAreaPadding(.bottom, 80)
                .onPreferenceChange(TaskRowFramePreferenceKey.self) { value in
                    rowFrames = value
                    if let id = activePushPopTaskID, let frame = value[id] {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            pickerAnchor = frame
                        }
                    }
                }
                .onPreferenceChange(CategoryButtonFramePreferenceKey.self) { value in
                    categoryButtonFrames = value
                    if let id = activePushPopTaskID, let frame = value[id] {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            pickerAnchor = frame
                        }
                    }
                }
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

                floatingAddButton
            }
            .safeAreaInset(edge: .top) {
                categoryTray
            }
        }
        .coordinateSpace(name: "pickerArea")
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
        .overlay(alignment: .topLeading) {
            if let taskID = activePushPopTaskID,
               let anchor = pickerAnchor,
               let task = tasks.first(where: { $0.id == taskID }) {
                CategoryPushPopPicker(
                    categories: categories,
                    anchorRect: anchor,
                    selectedCategoryID: task.category?.id,
                    isUnassigned: task.category == nil,
                    dragLocation: $pushPopDragLocation,
                    onSelection: { category in
                        Haptic.play(.dropSuccess)
                        apply(category: category, to: taskID)
                    },
                    onCancel: {
                        pushPopDragLocation = nil
                        dismissPicker()
                    }
                )
            }
        }
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

    private func categoryControl(for task: Task, tint: Color) -> some View {
        let icon = task.category?.icon ?? "circle.grid.cross.fill"
        return Button {
            if skipNextTapTaskID == task.id {
                skipNextTapTaskID = nil
                return
            }
            skipNextTapTaskID = nil
            Haptic.play(.tapLight)
            togglePicker(for: task.id)
        } label: {
            Image(systemName: icon)
                .font(.title3)
                .symbolRenderingMode(.palette)
                .foregroundStyle(tint)
                .padding(6)
                .background(
                    Circle()
                        .fill(tint.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: CategoryButtonFramePreferenceKey.self,
                    value: [task.id: proxy.frame(in: .named("pickerArea"))]
                )
            }
        )
        .simultaneousGesture(dragGesture(for: task))
        .accessibilityLabel("Change category")
    }

    private func dragGesture(for task: Task) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("pickerArea"))
            .onChanged { value in
                if activePushPopTaskID != task.id {
                    Haptic.play(.tapLight)
                    skipNextTapTaskID = task.id
                    presentPicker(for: task.id)
                }

                guard let anchor = pickerAnchor ?? categoryButtonFrames[task.id] else { return }
                pushPopDragLocation = CGPoint(
                    x: value.location.x - anchor.midX,
                    y: value.location.y - anchor.midY
                )
            }
            .onEnded { value in
                skipNextTapTaskID = nil
                guard activePushPopTaskID == task.id else { return }

                pushPopDragLocation = nil

                guard let anchor = pickerAnchor ?? categoryButtonFrames[task.id] else {
                    dismissPicker()
                    return
                }

                let relativeLocation = CGPoint(
                    x: value.location.x - anchor.midX,
                    y: value.location.y - anchor.midY
                )

                guard let result = CategoryPushPopPicker.selection(for: relativeLocation, categories: categories) else {
                    dismissPicker()
                    return
                }

                if result.isNone {
                    Haptic.play(.dropSuccess)
                    apply(category: nil, to: task.id)
                    return
                }

                if let id = result.categoryID,
                   let category = categories.first(where: { $0.id == id }) {
                    Haptic.play(.dropSuccess)
                    apply(category: category, to: task.id)
                    return
                }

                dismissPicker()
            }
    }

    private func presentPicker(for taskID: UUID) {
        let targetFrame = categoryButtonFrames[taskID] ?? rowFrames[taskID]
        if let frame = targetFrame {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                pickerAnchor = frame
                activePushPopTaskID = taskID
            }
        } else {
            activePushPopTaskID = taskID
        }
        pushPopDragLocation = nil
    }

    private func togglePicker(for taskID: UUID) {
        if activePushPopTaskID == taskID {
            dismissPicker()
        } else {
            pushPopDragLocation = nil
            presentPicker(for: taskID)
        }
    }

    private func taskRow(_ task: Task) -> some View {
        let fallback = Palette.defaultPreset
        let resolvedCategory = task.category ?? defaultCategory
        let tint = Palette.color(for: resolvedCategory?.colorID ?? fallback.colorID)
        let displayName = resolvedCategory?.name ?? fallback.name
        let displayIcon = resolvedCategory?.icon ?? fallback.icon
        return GlassCard(tint: tint) {
            HStack(alignment: .center, spacing: 16) {
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
                categoryControl(for: task, tint: tint)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture {
            toggle(task)
        }
        .onDrag {
            Haptic.play(.tapLight)
            return NSItemProvider(object: task.id.uuidString as NSString)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(task.title))
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: TaskRowFramePreferenceKey.self,
                    value: [task.id: proxy.frame(in: .named("pickerArea"))]
                )
            }
        )
    }

    private var scenicBackground: some View {
        ZStack {
            AuroraBackground()
                .blur(radius: 12)
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

    private var defaultCategory: Category? {
        categories.first { $0.sortOrder == 0 }
    }

    private var floatingAddButton: some View {
        Button(action: showAdd) {
            Label("Add", systemImage: "plus")
                .labelStyle(.iconOnly)
                .font(.title2.weight(.bold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(Palette.color(for: "Calm"))
                .padding()
                .background(
                    Circle()
                        .fill(.clear)
                        // Authentic Apple Liquid Glass for floating action button
                        .glassEffect(
                            .clear
                                .interactive(),
                            in: .circle
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.28), radius: 16, x: 0, y: 8)
                )
        }
        .buttonStyle(.plain)
        .padding(.trailing, 24)
        .padding(.bottom, 32)
        .accessibilityLabel("Add task")
    }

    private var categoryTray: some View {
        RoundedRectangle(cornerRadius: 36, style: .continuous)
            .fill(.clear)
            .frame(height: 112)
            // Authentic Apple Liquid Glass for category tray
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
                                                .clear
                                                    .interactive(),
                                                in: .rect(cornerRadius: 24)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                    .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
                                            )
                                            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 8)
                                        Image(systemName: "plus")
                                            .font(.title2.weight(.semibold))
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(Palette.color(for: "Calm"))
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
            .padding(.top, 12)
            .padding(.bottom, 4)
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

    private func apply(category: Category?, to taskID: UUID) {
        guard let task = tasks.first(where: { $0.id == taskID }) else {
            dismissPicker()
            return
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            task.category = category
        }
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to update task category: \(error.localizedDescription)")
        }
        dismissPicker()
    }

    private func dismissPicker() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            activePushPopTaskID = nil
            pickerAnchor = nil
        }
        pushPopDragLocation = nil
        skipNextTapTaskID = nil
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

private struct TaskRowFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] { [:] }

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct CategoryButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] { [:] }

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
