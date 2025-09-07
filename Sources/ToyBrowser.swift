// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Metal
import SDL2
import SkiaKit

@main
struct ToyBrowser: ParsableCommand {

    @Argument(help: "The URL to fetch and display")
    var urlString: String

    mutating func run() throws {

        let semaphore = DispatchSemaphore(value: 0)

        let finalUrl = urlString
        Task {
            _ = try await load(finalUrl)
            semaphore.signal()
        }

        semaphore.wait()

        // Initialize SDL video systems
        guard SDL_Init(SDL_INIT_VIDEO) == 0 else {
            fatalError("SDL could not initialize! SDL_Error: \(String(cString: SDL_GetError()))")
        }

        // Create a window at the center of the screen with 800x600 pixel resolution
        let window = SDL_CreateWindow(
            "SDL2 Minimal Demo",
            Int32(SDL_WINDOWPOS_CENTERED_MASK), Int32(SDL_WINDOWPOS_CENTERED_MASK),
            800, 600,
            SDL_WINDOW_SHOWN.rawValue)

        guard let window else {
            fatalError("Window could not be created! SDL_Error: \(String(cString: SDL_GetError()))")
        }

        var quit = false
        var event = SDL_Event()

        var circleX: Float = 400
        var direction: Float = 10

        // Run until app is quit
        while !quit {
            // Poll for (input) events
            while SDL_PollEvent(&event) > 0 {
                // if the quit event is triggered ...
                if event.type == SDL_QUIT.rawValue {
                    // ... quit the run loop
                    quit = true
                }
            }

            if (circleX > 600) {
                direction = -10
            } else if (circleX < 200) {
                direction = 10
            }

            circleX += direction

            guard let windowSurface = SDL_GetWindowSurface(window) else {
                fatalError(
                    "Could not get window surface! SDL_Error: \(String(cString: SDL_GetError()))")
            }

            let info = ImageInfo(
                width: windowSurface.pointee.w,
                height: windowSurface.pointee.h,
                colorType: .bgra8888,
                alphaType: .premul)

            let pixels = windowSurface.pointee.pixels!
            let rowBytes = Int(windowSurface.pointee.pitch)

            guard let skiaSurface = Surface.make(info, pixels, rowBytes) else {
                fatalError("Could not create Skia surface")
                continue
            }

            let canvas = skiaSurface.canvas
            canvas.clear(color: Color(r: 255, g: 255, b: 255))

            let paint = Paint()
            paint.color = Color(r: 0, g: 0, b: 0)
            paint.isAntialias = true
            paint.style = .fill

            guard let typeface = Typeface(familyName: "Arial", style: FontStyle(weight: .normal, width: .normal, slant: .upright)) else {
                fatalError("Could not create typeface")
            }
            canvas.draw(text: "Hello from Skia (CPU)!", x: 50, y: 100, font: Font(typeface: typeface, size: 16, scaleX: 1.0, skewX: 0.0), paint: paint)

            paint.color = Color(r: 255, g: 0, b: 0)
            canvas.drawCircle(circleX, 300, 100, paint)

            // Flushes are less critical here as we're writing to memory, but it's good practice.
            canvas.flush()

            // Step 4: Tell SDL to update the window with the new pixel data
            // SDL_UnlockSurface(windowSurface)
            SDL_UpdateWindowSurface(window)

            // wait 33 ms (30 FPS)
            SDL_Delay(33)
        }

        // Destroy the window
        SDL_DestroyWindow(window)

        // Quit all SDL systems
        SDL_Quit()
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
