import Foundation
import SkiaKit

struct WordLayoutData {
    let word: String
    let x: Float
    let y: Float
    let font: Font
}

@MainActor
func layoutText(_ tokens: [Token], maxWidth: Int32) -> [WordLayoutData] {
    let layout = Layout(tokens: tokens, maxWidth: maxWidth)
    layout.layout()
    return layout.layoutData
}

@MainActor
private class Layout {
    var layoutData: [WordLayoutData] = []
    var currentFont = createFont(weight: .normal, slant: .upright, size: 16.0)
    let lineHeight: Float
    let maxWidth: Int32
    let tokens: [Token]

    var currentX: Float = 0.0
    var currentY: Float = 0.0

    init(tokens: [Token], maxWidth: Int32) {
        self.tokens = tokens
        self.maxWidth = maxWidth
        self.lineHeight = currentFont.getMetrics()
    }

    func layout() {
        let fontSizeModifier: Float = 4.0

        for token in tokens {
            switch token {
            case .text(let text):
                layoutText(text)
            case .tag(let tag):
                let currentSize = currentFont.size
                let currentWeight = weightToEnumHelper(currentFont.typeface.fontStyle.weight)
                let currentSlant = currentFont.typeface.fontStyle.slant
                switch tag.lowercased() {
                case "br":
                    newLine()
                case "b":
                    currentFont = createFont(weight: .bold, slant: currentSlant, size: currentSize)
                case "/b":
                    currentFont = createFont(
                        weight: .normal, slant: currentSlant, size: currentSize)
                case "i":
                    currentFont = createFont(
                        weight: currentWeight, slant: .italic, size: currentSize)
                case "/i":
                    currentFont = createFont(
                        weight: currentWeight, slant: .upright, size: currentSize)
                case "small":
                    currentFont = createFont(
                        weight: currentWeight, slant: currentSlant,
                        size: currentSize - fontSizeModifier)
                case "/small":
                    currentFont = createFont(
                        weight: currentWeight, slant: currentSlant,
                        size: currentSize + fontSizeModifier)
                case "big":
                    currentFont = createFont(
                        weight: currentWeight, slant: currentSlant,
                        size: currentSize + fontSizeModifier)
                case "/big":
                    currentFont = createFont(
                        weight: currentWeight, slant: currentSlant,
                        size: currentSize - fontSizeModifier)
                default:
                    continue

                }
            }
        }
    }

    func layoutText(_ text: String) {
        let lines = text.split(separator: "\n")
        for (index, line) in lines.enumerated() {
            for word in line.split(separator: " ") {
                let wordWidth = currentFont.measureText(string: String(word))
                if currentX + wordWidth > Float(maxWidth) {
                    newLine()
                }

                layoutData.append(
                    WordLayoutData(word: String(word), x: currentX, y: currentY, font: currentFont))
                currentX += wordWidth + currentFont.measureText(string: " ")
            }

            if index < lines.count - 1 {
                newLine()
            }
        }
    }

    func newLine() {
        currentX = 0.0
        currentY += lineHeight * 1.25
    }
}

// Font cache to avoid recreating Font objects with the same parameters
@MainActor
private class FontCache {
    static let shared = FontCache()
    private var cache: [String: Font] = [:]

    func font(weight: FontStyleWeight, slant: FontStyleSlant, size: Float) -> Font {
        let key = "\(weight.rawValue)-\(slant.rawValue)-\(size)"
        if let cached = cache[key] {
            return cached
        }
        let fontStyle = FontStyle(weight: weight, width: .normal, slant: slant)
        guard let typeface = Typeface(familyName: "Arial", style: fontStyle) else {
            fatalError("Could not create typeface")
        }
        let font = Font(typeface: typeface, size: size, scaleX: 1.0, skewX: 0.0)
        cache[key] = font
        return font
    }
}

@MainActor
private func createFont(weight: FontStyleWeight, slant: FontStyleSlant, size: Float) -> Font {
    return FontCache.shared.font(weight: weight, slant: slant, size: size)
}

private func weightToEnumHelper(_ weight: Int32) -> FontStyleWeight {
    switch weight {
    case 100: return .thin
    case 200: return .extraLight
    case 300: return .light
    case 400: return .normal
    case 500: return .medium
    case 600: return .semiBold
    case 700: return .bold
    case 800: return .extraBold
    case 900: return .black
    default: return .normal
    }
}
