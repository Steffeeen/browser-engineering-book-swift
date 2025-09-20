import ArgumentParser
import SDL2
import SkiaKit

@main
struct ToyBrowser: AsyncParsableCommand {

    @Argument(help: "The URL to fetch and display")
    var urlString: String

    mutating func run() async throws {
        let tokens = try await load(urlString)

        guard let tokens else {
            print("Lexing failed, URL: \(urlString)")
            return
        }

        Task { @MainActor in
            displayBrowser(tokens: tokens)
        }
    }

}

@MainActor
func displayBrowser(tokens: [Token]) {
    let window =
        Window(width: 800, height: 600)
        ?? { fatalError("Could not create window") }()

    var scroll = 0
    var maxScroll = 0

    let scrollSpeed = 30
    window.registerKeyListener(forKey: SDLK_DOWN.rawValue) {
        scroll = min(max(0, scroll + scrollSpeed), maxScroll)
    }
    window.registerKeyListener(forKey: SDLK_UP.rawValue) {
        scroll = min(max(0, scroll - scrollSpeed), maxScroll)
    }

    window.registerScrollListener { x, y in
        // Invert y to match "normal" scrolling direction on macOS, this inverts the scroll direction on all other platforms
        let newScrollValue = Int(-y) * 3 + scroll
        scroll = min(max(0, newScrollValue), maxScroll)
    }

    let paint = Paint()
    paint.color = Color(r: 0, g: 0, b: 0)
    paint.isAntialias = true
    paint.style = .fill

    let margin: Int32 = 20

    var layoutData = layoutText(tokens, maxWidth: window.width - 2 * margin)
    maxScroll = Int((layoutData.last?.y ?? 0) + Float(margin) - Float(window.height / 2))

    window.registerResizeListener {
        layoutData = layoutText(tokens, maxWidth: window.width - 2 * margin)
        maxScroll = Int((layoutData.last?.y ?? 0) + Float(margin) - Float(window.height / 2))
    }

    var quit = false
    while !quit {
        quit = window.eventLoop { canvas in

            for wordData in layoutData {
                let x = wordData.x + Float(margin)
                let y = wordData.y + Float(margin) - Float(scroll)

                guard y >= Float(margin) && y <= Float(window.height - margin) else {
                    continue
                }

                let text = String(wordData.word)
                canvas.draw(text: text, x: x, y: y, font: wordData.font, paint: paint)

                if maxScroll > window.height {
                    drawScrollbar(
                        canvas: canvas,
                        window: window,
                        scroll: scroll,
                        maxScroll: maxScroll,
                        margin: margin)
                }
            }
        }

        // wait ~16ms (60fps)
        SDL_Delay(16)
    }
}

func drawScrollbar(canvas: Canvas, window: Window, scroll: Int, maxScroll: Int, margin: Int32) {
    let scrollbarWidth: Float = 6
    let scrollbarX = Float(window.width) - scrollbarWidth
    let scrollbarHeight =
        (Float(window.height) / (Float(maxScroll) + Float(window.height)))
        * Float(window.height - 2 * margin)
    let scrollbarY =
        (Float(scroll) / (Float(maxScroll) + Float(window.height)))
        * Float(window.height - 2 * margin)
        + Float(margin)

    let scrollbarRect = Rect(
        left: scrollbarX,
        top: scrollbarY,
        right: scrollbarX + scrollbarWidth,
        bottom: scrollbarY + scrollbarHeight)

    let scrollbarPaint = Paint()
    scrollbarPaint.color = Color(r: 200, g: 200, b: 200)
    scrollbarPaint.style = .fill
    canvas.drawRect(scrollbarRect, scrollbarPaint)
}

func load(_ urlString: String) async throws -> [Token]? {
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
    return lex(toShow)
}

