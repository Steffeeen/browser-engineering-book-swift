struct CharLayoutData {
    let char: Character
    let x: Float
    let y: Float
}

func layoutText(_ text: String, maxWidth: Int) -> [CharLayoutData] {
    var layoutData: [CharLayoutData] = []
    let spaceWidth: Int = 8 // Approximate width of a space character
    let lineHeight: Int = 18 // Approximate height of a line

    for (i, char) in text.enumerated() {
        let x = i * spaceWidth % maxWidth
        let y = (i * spaceWidth / maxWidth) * lineHeight

        layoutData.append(CharLayoutData(char: char, x: Float(x), y: Float(y)))
    }

    return layoutData
}