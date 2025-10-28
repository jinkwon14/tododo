import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

extension Color {
    init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hexString.count == 6 {
            hexString.append("FF")
        }
        guard hexString.count == 8, let intCode = UInt64(hexString, radix: 16) else {
            return nil
        }
        let r = Double((intCode & 0xFF000000) >> 24) / 255.0
        let g = Double((intCode & 0x00FF0000) >> 16) / 255.0
        let b = Double((intCode & 0x0000FF00) >> 8) / 255.0
        let a = Double(intCode & 0x000000FF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    func hexString() -> String? {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        let r = Int(round(red * 255))
        let g = Int(round(green * 255))
        let b = Int(round(blue * 255))
        let a = Int(round(alpha * 255))
        return String(format: "%02X%02X%02X%02X", r, g, b, a)
        #elseif canImport(AppKit)
        let nsColor = NSColor(self)
        guard let converted = nsColor.usingColorSpace(.sRGB) else { return nil }
        let r = Int(round(converted.redComponent * 255))
        let g = Int(round(converted.greenComponent * 255))
        let b = Int(round(converted.blueComponent * 255))
        let a = Int(round(converted.alphaComponent * 255))
        return String(format: "%02X%02X%02X%02X", r, g, b, a)
        #else
        return nil
        #endif
    }
}
