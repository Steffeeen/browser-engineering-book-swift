import ArgumentParser
import SDL2
import SkiaKit

@main
struct ToyBrowser: AsyncParsableCommand {

    @Argument(help: "The URL to fetch and display")
    var urlString: String

    mutating func run() async throws {
        let text = try await load(urlString) ?? ""

        let windowWidth: Int32 = 800
        let windowHeight: Int32 = 600

        Task { @MainActor in

            let window =
                Window(width: windowWidth, height: windowHeight)
                ?? { fatalError("Could not create window") }()

            var scroll = 0

            let scrollSpeed = 30
            window.registerKeyListener(forKey: SDLK_DOWN.rawValue) { scroll += scrollSpeed }
            window.registerKeyListener(forKey: SDLK_UP.rawValue) {
                scroll = max(0, scroll - scrollSpeed)
            }

            window.registerScrollListener { x, y in
                // Invert y to match "normal" scrolling direction on macOS, this inverts the scroll direction on all other platforms
                scroll = max(0, Int(-y) * 3 + scroll)
            }

            let paint = Paint()
            paint.color = Color(r: 0, g: 0, b: 0)
            paint.isAntialias = true
            paint.style = .fill

            let fontStyle = FontStyle(weight: .normal, width: .normal, slant: .upright)
            guard let typeface = Typeface(familyName: "Arial", style: fontStyle) else {
                fatalError("Could not create typeface")
            }

            let font = Font(typeface: typeface, size: 16, scaleX: 1.0, skewX: 0.0)
            let margin = 20

            let layoutData = layoutText(text, maxWidth: Int(windowWidth) - 2 * margin)

            var quit = false
            while !quit {
                quit = window.eventLoop { canvas in

                    for charData in layoutData {
                        let x = charData.x + Float(margin)
                        let y = charData.y + Float(margin) - Float(scroll)

                        guard y >= Float(margin) && y <= Float(Int(windowHeight) - margin) else {
                            continue
                        }

                        let text = String(charData.char)
                        canvas.draw(text: text, x: x, y: y, font: font, paint: paint)
                    }
                }

                // wait ~16ms (60fps)
                SDL_Delay(16)
            }
        }
    }
}

func load(_ urlString: String) async throws -> String? {
    guard let url = parseUrl(urlString) else {
        print("Invalid URL: \(urlString)")
        return nil
    }

    var response = try await fetchUrl(url)
    var currentUrl = url

    while case .http(_, let statusCode, _, let headers, _) = response,
        (300...399).contains(statusCode),
        let location = headers["location"]
    {
        print("Redirecting to \(location)")
        let newUrl =
            if location.starts(with: "/"), let networkUrl = currentUrl as? NetworkUrl {
                parseUrl("\(networkUrl.scheme)://\(networkUrl.host)\(location)")
            } else {
                parseUrl(location)
            }

        guard let newUrl else {
            print("Invalid redirect URL: \(location)")
            return nil
        }

        response = try await fetchUrl(newUrl)
        currentUrl = newUrl
    }

    if case .http(_, let statusCode, let statusMessage, _, _) = response {
        print("Got response: \(statusCode) \(statusMessage)")
    }

    let toShow = response.body
    print(lex(toShow))
    return lex(toShow)
}

func lex(_ html: String) -> String {
    var inTag = false
    var text = ""
    for char in html {
        if char == "<" {
            inTag = true
        } else if char == ">" {
            inTag = false
        } else if !inTag {
            text.append(char)
        }
    }
    return
        text
        .replacingOccurrences(of: "&lt;", with: "<")
        .replacingOccurrences(of: "&gt;", with: ">")
}
