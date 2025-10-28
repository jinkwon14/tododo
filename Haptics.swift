import UIKit

enum Haptic {
    case tapLight
    case dropSuccess
    case completeSuccess

    static func play(_ haptic: Haptic) {
        switch haptic {
        case .tapLight:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        case .dropSuccess:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred(intensity: 0.8)
        case .completeSuccess:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
    }
}
