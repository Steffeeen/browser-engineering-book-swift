import XCTest
@testable import ToyBrowser

final class UrlTests: XCTestCase {
    func testHttpUrl() {
        let url = parseUrl("http://example.org/index.html")
        guard let networkUrl = url as? NetworkUrl else {
            XCTFail("Expected NetworkUrl")
            return
        }
        switch networkUrl {
        case .http(let host, let port, let path):
            XCTAssertEqual(host, "example.org")
            XCTAssertEqual(port, 80)
            XCTAssertEqual(path, "/index.html")
        default:
            XCTFail("Expected .http case")
        }
    }

    func testHttpsUrl() {
        let url = parseUrl("https://example.org/foo/bar")
        guard let networkUrl = url as? NetworkUrl else {
            XCTFail("Expected NetworkUrl")
            return
        }
        switch networkUrl {
        case .https(let host, let port, let path):
            XCTAssertEqual(host, "example.org")
            XCTAssertEqual(port, 443)
            XCTAssertEqual(path, "/foo/bar")
        default:
            XCTFail("Expected .https case")
        }
    }

    func testFileUrl() {
        let url = parseUrl("file:///tmp/test.txt")
        guard let fileUrl = url as? FileUrl else {
            XCTFail("Expected FileUrl")
            return
        }
        XCTAssertEqual(fileUrl.path, "/tmp/test.txt")
    }

    func testDataUrl() {
        let url = parseUrl("data:text/html,<h1>Hello</h1>")
        guard let dataUrl = url as? DataUrl else {
            XCTFail("Expected DataUrl")
            return
        }
        XCTAssertEqual(dataUrl.data, "<h1>Hello</h1>")
    }

    func testViewSourceUrl() {
        let url = parseUrl("view-source:http://example.org/")
        guard let viewSourceUrl = url as? ViewSourceUrl else {
            XCTFail("Expected ViewSourceUrl")
            return
        }
        guard let inner = viewSourceUrl.url as? NetworkUrl else {
            XCTFail("Expected inner NetworkUrl")
            return
        }
        switch inner {
        case .http(let host, let port, let path):
            XCTAssertEqual(host, "example.org")
            XCTAssertEqual(port, 80)
            XCTAssertEqual(path, "/")
        default:
            XCTFail("Expected .http case")
        }
    }
}
