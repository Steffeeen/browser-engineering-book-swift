class HtmlParser {
    private var unfinishedNodes = [HtmlNode]()
    private let html: String

    init(html: String) {
        self.html = html
    }

    func parse() -> HtmlNode? {
        var text = ""
        var inTag = false

        for char in html {
            switch char {
            case "<":
                inTag = true
                if !text.isEmpty {
                    createTextNode(text)
                    text = ""
                }
            case ">":
                inTag = false
                handleTag(text)
                text = ""
            default:
                text.append(char)
            }
        }

        if !inTag && !text.isEmpty {
            createTextNode(text)
        }

        return finish()
    }

    private func handleTag(_ tagName: String) {
        if tagName.hasPrefix("!") {
            // ignore doctype and comments
            return
        }

        if tagName.hasPrefix("/") {
            if unfinishedNodes.count == 1 {
                return
            }
            let node = unfinishedNodes.popLast()
            var parent = unfinishedNodes.last
            parent?.children.append(node!)
        } else {
            let parent = unfinishedNodes.last
            let node = ElementNode(name: tagName, parent: parent)
            unfinishedNodes.append(node)
        }
    }

    private func createTextNode(_ text: String) {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }

        var parent = unfinishedNodes.last
        let node = TextNode(text: text, parent: parent)
        if parent != nil {
            parent?.children.append(node)
        } else {
            unfinishedNodes.append(node)
        }
    }

    private func finish() -> HtmlNode? {
        while unfinishedNodes.count > 1 {
            let node = unfinishedNodes.popLast()
            var parent = unfinishedNodes.last
            parent?.children.append(node!)
        }

        print("Parsed the following HTML:")
        print(html)
        print()
        print("Into the following structure (\(unfinishedNodes.count) unfinished nodes):")
        for node in unfinishedNodes {
            printNode(node)
        }

        return unfinishedNodes.popLast()
    }

    private func printNode(_ node: HtmlNode, indent: String = "") {
        if let element = node as? ElementNode {
            print("\(indent)ElementNode: <\(element.name)>")
            for child in element.children {
                printNode(child, indent: indent + "  ")
            }
        } else if let text = node as? TextNode {
            print("\(indent)Text: \(text.text)")
        }
    }
}
