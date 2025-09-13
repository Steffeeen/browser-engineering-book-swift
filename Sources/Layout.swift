struct CharLayoutData {
    let char: Character
    let x: Float
    let y: Float
}

func layoutText(_ text: String, maxWidth: Int) -> [CharLayoutData] {
    var layoutData: [CharLayoutData] = []
    let spaceWidth: Int = 8 // Approximate width of a space character
    let lineHeight: Int = 18 // Approximate height of a line

    var currentX = 0
    var currentY = 0
    for char in text {
        if char == "\n" {
            currentX = 0
            currentY += lineHeight
            print("Laying out newline at (\(currentX), \(currentY))")
            continue
        }

        print("Laying out char '\(char)' at (\(currentX), \(currentY))")
        layoutData.append(CharLayoutData(char: char, x: Float(currentX), y: Float(currentY)))

        currentX += spaceWidth
        if currentX > maxWidth {
            print("Wrapping line at char '\(char)' because currentX \(currentX) > maxWidth \(maxWidth)")
            currentX = 0
            currentY += lineHeight
        }
    }

    return layoutData
}