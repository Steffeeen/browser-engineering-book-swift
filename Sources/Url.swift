import Socket

private let HTTP_PORT: Int32 = 80

enum RequestError : Error {
    case noResponse
    case invalidResponse
}

struct Url {
    let scheme: String
    let host: String
    let path: String

    func request() async throws {
        let socket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
        try socket.connect(to: host, port: HTTP_PORT)

        var request = """
            GET \(path) HTTP/1.0
            Host: \(host)
            """

        request += "\r\n\r\n"
        try socket.write(from: request)

        let response = try socket.readString()
        if let response = response {
            let lines = response.components(separatedBy: "\r\n")
            let statusLineParts = lines[0].components(separatedBy: " ")

        } else {
            throw RequestError.noResponse
        }

        

    }
}

func parseUrl(_ url: String) -> Url? {
    let scheme = url.components(separatedBy: "://").first
    let host = url.components(separatedBy: "://").last?.components(separatedBy: "/").first
    let path = url.components(separatedBy: "://").last?.components(separatedBy: "/").dropFirst().joined(separator: "/")

    if let scheme = scheme, scheme == "http", let host = host, let path = path {
        return Url(scheme: scheme, host: host, path: "/\(path)")
    }
    return nil
}