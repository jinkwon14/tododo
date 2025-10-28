import SwiftUI

enum Palette {
    private static let colors: [String: Color] = [
        "Inbox": Color(red: 0.85, green: 0.9, blue: 0.95),
        "Work": Color(red: 0.45, green: 0.63, blue: 0.95),
        "Home": Color(red: 0.62, green: 0.78, blue: 0.63),
        "Errands": Color(red: 0.98, green: 0.74, blue: 0.57),
        "Health": Color(red: 0.74, green: 0.69, blue: 0.96),
        "Play": Color(red: 0.98, green: 0.64, blue: 0.78),
        "Learning": Color(red: 0.54, green: 0.79, blue: 0.84),
        "Calm": Color(red: 0.73, green: 0.87, blue: 0.92)
    ]

    static let defaultPreset: (name: String, icon: String, colorID: String) =
        ("Inbox", "tray.fill", "Inbox")

    static func color(for id: String?) -> Color {
        guard let id else {
            return colors[defaultPreset.colorID] ?? Color(red: 0.85, green: 0.9, blue: 0.95)
        }
        if let color = colors[id] {
            return color
        }
        if let parsed = Color(hex: id) {
            return parsed
        }
        return colors[defaultPreset.colorID] ?? Color(red: 0.85, green: 0.9, blue: 0.95)
    }

    static var defaults: [(name: String, icon: String, colorID: String)] {
        [
            defaultPreset,
            ("Work", "briefcase.fill", "Work"),
            ("Home", "house.fill", "Home"),
            ("Errands", "cart.fill", "Errands"),
            ("Health", "heart.fill", "Health"),
            ("Play", "gamecontroller.fill", "Play"),
            ("Learning", "book.fill", "Learning")
        ]
    }
}
