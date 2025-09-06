// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import SDL2
import SkiaKit

@main
struct ToyBrowser: AsyncParsableCommand {

    @Argument(help: "The URL to fetch and display")
    var urlString: String

    mutating func run() async throws {
        guard let url = parseUrl(urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }

        let response = try await url.request()
        print("Got response: \(response.statusCode) \(response.statusMessage)")
        print(show(response.body))

        // Initialize SDL video systems
        // guard SDL_Init(SDL_INIT_VIDEO) == 0 else {
        //     fatalError("SDL could not initialize! SDL_Error: \(String(cString: SDL_GetError()))")
        // }

        // // Create a window at the center of the screen with 800x600 pixel resolution
        // let window = SDL_CreateWindow(
        //     "SDL2 Minimal Demo",
        //     Int32(SDL_WINDOWPOS_CENTERED_MASK), Int32(SDL_WINDOWPOS_CENTERED_MASK),
        //     800, 600,
        //     SDL_WINDOW_SHOWN.rawValue)

        // var quit = false
        // var event = SDL_Event()

        // // Run until app is quit
        // while !quit {
        //     // Poll for (input) events
        //     while SDL_PollEvent(&event) > 0 {
        //         // if the quit event is triggered ...
        //         if event.type == SDL_QUIT.rawValue {
        //             // ... quit the run loop
        //             quit = true
        //         }
        //     }

        //     // wait 100 ms
        //     SDL_Delay(100)
        // }

        // // Destroy the window
        // SDL_DestroyWindow(window)

        // // Quit all SDL systems
        // SDL_Quit()
    }
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
    return text
}