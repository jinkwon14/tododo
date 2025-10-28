import Foundation
import SwiftData

@Model
final class Task: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String?
    var due: Date?
    var isDone: Bool
    var createdAt: Date
    var completedAt: Date?
    var priority: Int?
    var tags: [String]
    var category: Category?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        due: Date? = nil,
        isDone: Bool = false,
        createdAt: Date = .now,
        completedAt: Date? = nil,
        priority: Int? = nil,
        tags: [String] = [],
        category: Category? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.due = due
        self.isDone = isDone
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.priority = priority
        self.tags = tags
        self.category = category
    }
}

@Model
final class Category: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorID: String
    var icon: String
    var sortOrder: Int
    @Relationship(deleteRule: .cascade, inverse: \Task.category)
    var tasks: [Task]

    init(
        id: UUID = UUID(),
        name: String,
        colorID: String,
        icon: String,
        sortOrder: Int = 0,
        tasks: [Task] = []
    ) {
        self.id = id
        self.name = name
        self.colorID = colorID
        self.icon = icon
        self.sortOrder = sortOrder
        self.tasks = tasks
    }
}

@Model
final class UserSettings {
    var hapticsOn: Bool
    var soundsOn: Bool
    var companion: String
    var iCloudSyncOn: Bool

    init(
        hapticsOn: Bool = true,
        soundsOn: Bool = true,
        companion: String = "Glow",
        iCloudSyncOn: Bool = true
    ) {
        self.hapticsOn = hapticsOn
        self.soundsOn = soundsOn
        self.companion = companion
        self.iCloudSyncOn = iCloudSyncOn
    }
}
