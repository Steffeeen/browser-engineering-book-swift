import SDL2
import SkiaKit

class Window {

    private let window: OpaquePointer

    init?() {
        guard SDL_Init(SDL_INIT_VIDEO) == 0 else {
            fatalError("SDL could not initialize! SDL_Error: \(String(cString: SDL_GetError()))")
        }

        let maybeWindow = SDL_CreateWindow(
            "Toy Browser",
            Int32(SDL_WINDOWPOS_CENTERED_MASK), Int32(SDL_WINDOWPOS_CENTERED_MASK),
            800, 600,
            SDL_WINDOW_SHOWN.rawValue)

        guard let window = maybeWindow else {
            fatalError("Window could not be created! SDL_Error: \(String(cString: SDL_GetError()))")
        }

        self.window = window
    }

    deinit {
        SDL_DestroyWindow(window)
        SDL_Quit()
    }

    func eventLoop(canvasDrawingFunction: (Canvas) -> Void) -> Bool {
        var event = SDL_Event()

        while SDL_PollEvent(&event) > 0 {
            if event.type == SDL_QUIT.rawValue {
                return true
            }
        }

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
            }

            let canvas = skiaSurface.canvas
            canvas.clear(color: Color(r: 255, g: 255, b: 255))

            canvasDrawingFunction(canvas)

            canvas.flush()

            SDL_UpdateWindowSurface(window)

        return false
    }

}
