import Foundation
import SSLService
import Socket

enum Response {
    case http(
        version: String, statusCode: Int, statusMessage: String, headers: [String: String],
        body: String)
    case file(contents: String)
    case data(contents: String)
    
    var body: String {
        switch self {
        case .http(_, _, _, _, let body):
            return body
        case .file(let contents):
            return contents
        case .data(let contents):
            return contents
        }
    }
}

enum RequestError: Error {
    case noResponse
    case invalidStatusLine(elements: [String])
    case unsupportedHeaders
    case decodingError
}

func fetchUrl(_ url: Url) async throws -> Response {
    switch url {
    case let networkUrl as NetworkUrl:
        return try await fetchHttpUrl(networkUrl)
    case let fileUrl as FileUrl:
        let contents = try String(contentsOfFile: fileUrl.path, encoding: .utf8)
        return Response.file(contents: contents)
    case let dataUrl as DataUrl:
        return Response.data(contents: dataUrl.data)

    default:
        throw RequestError.noResponse
    }
}

private func fetchHttpUrl(_ url: NetworkUrl) async throws -> Response {
    let socket = try Socket.create(family: .inet, type: .stream, proto: .tcp)

    if case .https(_, _, _) = url {
        let sslConfig = SSLService.Configuration()
        let sslService = try SSLService(usingConfiguration: sslConfig)
        socket.delegate = sslService
    }
    print("Connecting to \(url.host):\(url.port)...")
    try socket.connect(to: url.host, port: url.port)

    var request = """
        GET \(url.path) HTTP/1.1
        Host: \(url.host)
        Connection: close
        User-Agent: ToyBrowser/0.1
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

    return Response.http(
        version: version,
        statusCode: Int(statusCode) ?? -1,
        statusMessage: statusMessage,
        headers: headers,
        body: body
    )
}
