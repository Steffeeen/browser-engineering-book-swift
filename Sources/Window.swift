import SDL2
import SkiaKit


class Window {
    private let window: OpaquePointer
    // Listener: (key: Int32, eventType: UInt32, handler: (SDL_Keysym, UInt32) -> Void)
    private var keyListeners: [(key: UInt32, handler: () -> Void)] = []

    init?(width: Int32, height: Int32) {
        guard SDL_Init(SDL_INIT_VIDEO) == 0 else {
            fatalError("SDL could not initialize! SDL_Error: \(String(cString: SDL_GetError()))")
        }

        let maybeWindow = SDL_CreateWindow(
            "Toy Browser",
            Int32(SDL_WINDOWPOS_CENTERED_MASK), Int32(SDL_WINDOWPOS_CENTERED_MASK),
            Int32(width), Int32(height),
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


    /// Register a key listener for a specific key and event type (e.g. SDL_KEYDOWN/SDL_KEYUP)
    func registerKeyListener(forKey key: UInt32, handler: @escaping () -> Void) {
        keyListeners.append((key: key, handler: handler))
    }

    func eventLoop(canvasDrawingFunction: (Canvas) -> Void) -> Bool {
        var event = SDL_Event()

        while SDL_PollEvent(&event) > 0 {
            switch event.type {
            case SDL_QUIT.rawValue:
                return true
            case SDL_KEYDOWN.rawValue:
                for listener in keyListeners {
                    if event.key.keysym.sym == listener.key {
                        listener.handler()
                    }
                }
            default:
                break
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
