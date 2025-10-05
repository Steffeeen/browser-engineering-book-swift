enum Token {
    case text(String)
    case tag(String)
}

func lex(_ html: String) -> [Token] {
    var tokens: [Token] = []

    var buffer = ""
    var inTag = false
    for char in html {
        switch char {
            case "<":
                inTag = true
                if !buffer.isEmpty {
                    tokens.append(.text(processText(buffer)))
                    buffer = ""
                }
            case ">":
                inTag = false
                tokens.append(.tag(buffer))
                buffer = ""
            default:
                buffer.append(char)
        }
    }

    if !inTag && !buffer.isEmpty {
        tokens.append(.text(processText(buffer)))
    }

    let parser = HtmlParser(html: html)
    parser.parse()

    return tokens
}

private func processText(_ text: String) -> String {
    return text
        .replacingOccurrences(of: "&amp;", with: "&")
        .replacingOccurrences(of: "&lt;", with: "<")
        .replacingOccurrences(of: "&gt;", with: ">")
}