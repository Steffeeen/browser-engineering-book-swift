import SkiaKit

struct WordLayoutData {
    let word: String
    let x: Float
    let y: Float
}

func layoutText(_ text: String, maxWidth: Int32, font: Font) -> [WordLayoutData] {
    var layoutData: [WordLayoutData] = []
    let lineHeight = font.getMetrics()
    let spaceWidth = font.measureText(string: " ")

    var currentX: Float = 0.0
    var currentY: Float = 0.0
    for line in text.split(separator: "\n") {
        for word in line.split(separator: " ") {
            let wordWidth = font.measureText(string: String(word))
            if currentX + wordWidth > Float(maxWidth) {
                currentX = 0.0
                currentY += lineHeight * 1.25
            }

            layoutData.append(WordLayoutData(word: String(word), x: currentX, y: currentY))
            currentX += wordWidth + spaceWidth
        }

        currentX = 0.0
        currentY += lineHeight * 1.25
    }

    return layoutData
}
