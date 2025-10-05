protocol HtmlNode {
    var children: [HtmlNode] { get set }
    var parent: HtmlNode? { get set }
}

class TextNode: HtmlNode {
    var text: String
    var children: [HtmlNode] = []
    var parent: HtmlNode?

    init(text: String, parent: HtmlNode?) {
        self.text = text
        self.parent = parent
    }
}

class ElementNode: HtmlNode {
    var name: String
    var children: [HtmlNode] = []
    var parent: HtmlNode?

    init(name: String, parent: HtmlNode?) {
        self.name = name
        self.parent = parent
    }
}