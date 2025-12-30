private let voidElementNames: Set<String> = [
    "area", "base", "br", "col", "embed", "hr", "img", "input",
    "link", "meta", "source", "track", "wbr"
]

private let tagsInHead: Set<String> = [
    "base", "basefont", "bgsound", "noscript", "link", "meta", "title", "style", "script"
]

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

    private func handleTag(_ tag: String) {
        if tag.hasPrefix("!") {
            // ignore doctype and comments
            return
        }

        let (tagName, attributes) = getAttributes(from: tag)
        handleImplicitTags(for: tagName)

        if tagName.hasPrefix("/") {
            if unfinishedNodes.count == 1 {
                return
            }
            let node = unfinishedNodes.popLast()
            var parent = unfinishedNodes.last
            parent?.children.append(node!)
        } else {
            var parent = unfinishedNodes.last
            let node = ElementNode(name: tagName, attributes: attributes, parent: parent)
            if voidElementNames.contains(tagName) {
                parent?.children.append(node)
            } else {
                unfinishedNodes.append(node)
            }
        }
    }

    private func handleImplicitTags(for tag: String?) {
        while true {
            let openTags = unfinishedNodes.compactMap { ($0 as? ElementNode)?.name }

            if openTags.isEmpty && tag != "html" {
                handleTag("html")
            } else if openTags == ["html"] && !["head", "body", "/html"].contains(tag) && tag != nil {
                if tagsInHead.contains(tag!) {
                    handleTag("head")
                } else {
                    handleTag("body")
                }
            } else if openTags == ["html", "head"] && tag != nil && !tagsInHead.contains(tag!) && tag != "/head" {
                handleTag("/head")
            } else {
                break
            }
        }
    }

    private func getAttributes(from tag: String) -> (String, [String: String]) {
        print(tag)
        if tag.starts(with: "/") {
            print("tag starts with /")
            return (tag.lowercased(), [:])
        }

        let parts = tag.split(separator: " ")
        let tagName = parts[0].lowercased()
        var attributes: [String: String] = [:]
        for part in parts.dropFirst() {
            if part.contains("=") {
                let split = part.split(separator: "=", maxSplits: 1)

                var value = split[1]
                if value.first == "'" || value.first == "\"" {
                    value = value.dropFirst().dropLast()
                }

                attributes[split[0].lowercased()] = String(value)
            } else {
                // attribute has no value
                attributes[part.lowercased()] = ""
            }
        }
        return (tagName, attributes)
    }

    private func createTextNode(_ text: String) {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }

        handleImplicitTags(for: nil)

        var parent = unfinishedNodes.last
        let node = TextNode(text: processText(text), parent: parent)
        if parent != nil {
            parent?.children.append(node)
        } else {
            unfinishedNodes.append(node)
        }
    }

    private func processText(_ text: String) -> String {
    return text
        .replacingOccurrences(of: "&amp;", with: "&")
        .replacingOccurrences(of: "&lt;", with: "<")
        .replacingOccurrences(of: "&gt;", with: ">")
}

    private func finish() -> HtmlNode? {
        if !unfinishedNodes.isEmpty {
            handleImplicitTags(for: nil)
        }

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
            print("\(indent)ElementNode: <\(element.name)> with attributes: \(element.attributes)")
            for child in element.children {
                printNode(child, indent: indent + "  ")
            }
        } else if let text = node as? TextNode {
            print("\(indent)Text: \(text.text)")
        }
    }
}
