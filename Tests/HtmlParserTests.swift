import XCTest
@testable import ToyBrowser

final class HtmlParserTests: XCTestCase {
    func testParseSingleElement() {
        let html = "<div>hello</div>"
        let parser = HtmlParser(html: html)
        guard let root = parser.parse() as? ElementNode else {
            XCTFail("Root should be an ElementNode")
            return
        }
        XCTAssertEqual(root.name, "div")
        XCTAssertEqual(root.children.count, 1)
        guard let textNode = root.children.first as? TextNode else {
            XCTFail("Child should be a TextNode")
            return
        }
        XCTAssertEqual(textNode.text, "hello")
    }

    func testParseNestedElements() {
        let html = "<div><span>hi</span></div>"
        let parser = HtmlParser(html: html)
        guard let root = parser.parse() as? ElementNode else {
            XCTFail("Root should be an ElementNode")
            return
        }
        XCTAssertEqual(root.name, "div")
        XCTAssertEqual(root.children.count, 1)
        guard let span = root.children.first as? ElementNode else {
            XCTFail("Child should be an ElementNode")
            return
        }
        XCTAssertEqual(span.name, "span")
        XCTAssertEqual(span.children.count, 1)
        guard let textNode = span.children.first as? TextNode else {
            XCTFail("Child of span should be a TextNode")
            return
        }
        XCTAssertEqual(textNode.text, "hi")
    }

    func testParseTextOnly() {
        let html = "hello world"
        let parser = HtmlParser(html: html)
        guard let root = parser.parse() as? TextNode else {
            XCTFail("Root should be a TextNode")
            return
        }
        XCTAssertEqual(root.text, "hello world")
    }
}
