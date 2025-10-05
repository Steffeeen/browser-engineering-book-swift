import Foundation
import SkiaKit

struct WordLayoutData {
    let word: String
    let x: Float
    let y: Float
    let font: Font
}

@MainActor
func layoutText(_ rootNode: HtmlNode, maxWidth: Int32) -> [WordLayoutData] {
    let layout = Layout(rootNode: rootNode, maxWidth: maxWidth)
    layout.layout()
    return layout.layoutData
}

@MainActor
private class Layout {
    var layoutData: [WordLayoutData] = []

    let fontSizeModifier: Float = 4.0
    var currentSize: Float = 16.0
    var currentWeight = FontStyleWeight.normal
    var currentSlant = FontStyleSlant.upright
    var currentFont: Font
    
    let lineHeight: Float
    let maxWidth: Int32
    let rootNode: HtmlNode

    var currentX: Float = 0.0
    var currentY: Float = 0.0

    init(rootNode: HtmlNode, maxWidth: Int32) {
        self.rootNode = rootNode
        self.maxWidth = maxWidth
        self.currentFont = FontCache.shared.font(weight: currentWeight, slant: currentSlant, size: currentSize)
        self.lineHeight = currentFont.getMetrics()
    }

    func layout() {
        traverse(node: rootNode)
    }

    func traverse(node: HtmlNode) {
        if let element = node as? ElementNode {
            handleTagOpen(element.name)
            for child in element.children {
                traverse(node: child)
            }
            handleTagClose(element.name)
        } else if let textNode = node as? TextNode {
            layoutText(textNode.text)
        }
    }

    func handleTagOpen(_ tag: String) {
        switch tag {
            case "b":
                currentWeight = .bold
                recreateFont()
            case "i":
                currentSlant = .italic
                recreateFont()
            case "small":
                currentSize = max(1.0, currentSize - fontSizeModifier)
                recreateFont()
            case "big":
                currentSize += fontSizeModifier
                recreateFont()
            default:
                break
        }
    }

    func handleTagClose(_ tag: String) {
        switch tag {
            case "b":
                currentWeight = .normal
                recreateFont()
            case "i":
                currentSlant = .upright
                recreateFont()
            case "small":
                currentSize += fontSizeModifier
                recreateFont()
            case "big":
                currentSize = max(1.0, currentSize - fontSizeModifier)
                recreateFont()
            default:
                break
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

    func recreateFont() {
        currentFont = FontCache.shared.font(weight: currentWeight, slant: currentSlant, size: currentSize)
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
