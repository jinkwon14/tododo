import SwiftData

enum PreviewSampleData {
    static var container: ModelContainer = {
        let schema = Schema([Task.self, Category.self, UserSettings.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])

        let context = ModelContext(container)
        Palette.defaults.enumerated().forEach { index, item in
            let category = Category(name: item.name, colorID: item.colorID, icon: item.icon, sortOrder: index)
            context.insert(category)
        }

        for idx in 0..<6 {
            let task = Task(title: "Sample Task \(idx + 1)")
            context.insert(task)
        }

        return container
    }()
}
