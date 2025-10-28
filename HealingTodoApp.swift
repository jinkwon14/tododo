import SwiftUI
import SwiftData

@main
struct HealingTodoAppApp: App {
    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([Task.self, Category.self, UserSettings.self])
        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            InboxView()
        }
        .modelContainer(sharedModelContainer)
    }
}
