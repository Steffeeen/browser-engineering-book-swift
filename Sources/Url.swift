import Foundation
import SSLService
import Socket

private let schemesToPort: [String: Int32] = [
    "http": 80,
    "https": 443,
]

protocol Url {}

protocol PathUrl: Url {
    var path: String { get }
}

enum NetworkUrl: PathUrl {
    case http(host: String, port: Int32, path: String)
    case https(host: String, port: Int32, path: String)

    var path: String {
        switch self {
        case .http(_, _, let path): return path
        case .https(_, _, let path): return path
        }
    }

    var host: String {
        switch self {
        case .http(let host, _, _): return host
        case .https(let host, _, _): return host
        }
    }

    var port: Int32 {
        switch self {
        case .http(_, let port, _): return port
        case .https(_, let port, _): return port
        }
    }

    var scheme : String {
        switch self {
        case .http: return "http"
        case .https: return "https"
        }
    }
}

struct FileUrl: PathUrl {
    let path: String
}

struct DataUrl: Url {
    let data: String
}

struct ViewSourceUrl: Url {
    let url: Url
}

func parseUrl(_ url: String) -> Url? {
    let scheme = url.components(separatedBy: ":").first

    if scheme == "file" {
        let path = url.components(separatedBy: "://").last ?? ""
        return FileUrl(path: path)
    }

    if scheme == "data" {
        let regex = /^data:(.*),(.*)$/
        if let match = try? regex.wholeMatch(in: url), match.1 == "text/html" {
            return DataUrl(data: String(match.2))
        }
        return nil
    }

    if scheme == "view-source" {
        let regex = /^view-source:(.*)$/

        guard let match = try? regex.wholeMatch(in: url) else { return nil }

        let innerUrlString = String(match.1)
        if let innerUrl = parseUrl(innerUrlString) {
            return ViewSourceUrl(url: innerUrl)
        }
        return nil
    }

    guard let scheme = scheme, let schemePort = schemesToPort[scheme] else {
        return nil
    }

    let host = url.components(separatedBy: "://").last?.components(separatedBy: "/").first
    let path = url.components(separatedBy: "://").last?.components(separatedBy: "/").dropFirst()
        .joined(separator: "/")

    if let hostWithMaybePort = host, let path = path {
        let port =
            if hostWithMaybePort.contains(":"),
                let p = hostWithMaybePort.components(separatedBy: ":").last, let portNum = Int32(p)
            {
                portNum
            } else {
                schemePort
            }

        let host = hostWithMaybePort.components(separatedBy: ":").first!
        return if scheme == "http" {
            NetworkUrl.http(host: host, port: port, path: "/\(path)")
        } else {
            NetworkUrl.https(host: host, port: port, path: "/\(path)")
        }
    }
    return nil
}
