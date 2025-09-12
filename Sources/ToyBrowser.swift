import ArgumentParser
import SDL2
import SkiaKit

@main
struct ToyBrowser: AsyncParsableCommand {

    @Argument(help: "The URL to fetch and display")
    var urlString: String

    mutating func run() async throws {
        let html = try await load(urlString)

        Task { @MainActor in

            let window = Window() ?? { fatalError("Could not create window") }()

            var circleX: Float = 400
            var direction: Float = 10

            var quit = false
            while !quit {
                quit = window.eventLoop { canvas in

                    if circleX > 600 {
                        direction = -10
                    } else if circleX < 200 {
                        direction = 10
                    }

                    circleX += direction

                    let paint = Paint()
                    paint.color = Color(r: 0, g: 0, b: 0)
                    paint.isAntialias = true
                    paint.style = .fill

                    guard
                        let typeface = Typeface(
                            familyName: "Arial",
                            style: FontStyle(weight: .normal, width: .normal, slant: .upright))
                    else {
                        fatalError("Could not create typeface")
                    }

                    canvas.draw(
                        text: "Hello from Skia (CPU)!", x: 50, y: 100,
                        font: Font(typeface: typeface, size: 16, scaleX: 1.0, skewX: 0.0),
                        paint: paint)

                    paint.color = Color(r: 255, g: 0, b: 0)
                    canvas.drawCircle(circleX, 300, 100, paint)
                }

                // wait 33 ms (30 FPS)
                SDL_Delay(33)
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
    print(show(toShow))
    return show(toShow)
}

func show(_ html: String) -> String {
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
