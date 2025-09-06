import Socket
import SSLService
import Foundation

private let schemesToPort: [String: Int32] = [
    "http": 80,
    "https": 443
]

enum RequestError: Error {
    case noResponse
    case invalidStatusLine(elements: Array<String>)
    case unsupportedHeaders
    case decodingError
}

struct Response {
    let version: String
    let statusCode: Int
    let statusMessage: String
    let headers: [String: String]
    let body: String
}

struct Url {
    let scheme: String
    let host: String
    let port: Int32
    let path: String

    func request() async throws -> Response {
        let socket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
        if scheme == "https" {
            let sslConfig = SSLService.Configuration()
            let sslService = try SSLService(usingConfiguration: sslConfig)
            socket.delegate = sslService
        }
        print("Connecting to \(host):\(port)...")
        try socket.connect(to: host, port: port)

        var request = """
            GET \(path) HTTP/1.0
            Host: \(host)
            """

        request += "\r\n\r\n"
        try socket.write(from: request)

        var responseData = Data(capacity: socket.readBufferSize)
        try socket.read(into: &responseData)

        socket.close()
        guard let response = String(data: responseData, encoding: .utf8), !response.isEmpty else {
            throw RequestError.decodingError
        }

        let lines = response.components(separatedBy: "\r\n")
        let statusLineParts = lines[0].components(separatedBy: " ")
        if statusLineParts.count != 3 {
            throw RequestError.invalidStatusLine(elements: statusLineParts)
        }
        let (version, statusCode, statusMessage) = (
            statusLineParts[0], statusLineParts[1], statusLineParts[2]
        )
        let headers = {
            let headerLines = lines.dropFirst().prefix { !$0.isEmpty }
            let tuples = headerLines.map { $0.components(separatedBy: ": ") }
                .filter { $0.count == 2 }
                .map { ($0[0].lowercased(), $0[1].trimmingCharacters(in: .whitespaces)) }

            return Dictionary(uniqueKeysWithValues: tuples)
        }()

        if headers["transfer-encoding"] != nil || headers["content-encoding"] != nil {
            throw RequestError.unsupportedHeaders
        }

        let bodyLines = lines.dropFirst().drop { !$0.isEmpty }.dropFirst()
        let body = bodyLines.joined(separator: "\r\n")

        return Response(
            version: version,
            statusCode: Int(statusCode) ?? -1,
            statusMessage: statusMessage,
            headers: headers,
            body: body
        )
    }
}

func parseUrl(_ url: String) -> Url? {
    let scheme = url.components(separatedBy: "://").first
    let host = url.components(separatedBy: "://").last?.components(separatedBy: "/").first
    let path = url.components(separatedBy: "://").last?.components(separatedBy: "/").dropFirst()
        .joined(separator: "/")

    if let scheme = scheme, let schemePort = schemesToPort[scheme], let hostWithMaybePort = host, let path = path {
        let port = if hostWithMaybePort.contains(":"), let p = hostWithMaybePort.components(separatedBy: ":").last, let portNum = Int32(p) {
            portNum
        } else {
            schemePort
        }

        let host = hostWithMaybePort.components(separatedBy: ":").first!
        return Url(scheme: scheme, host: host, port: port, path: "/\(path)")
    }
    return nil
}
