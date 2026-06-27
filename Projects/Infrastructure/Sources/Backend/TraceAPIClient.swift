import Foundation

/// Non-2xx HTTP response from the TRACE API.
public struct APIError: Error, Sendable {
    public let status: Int
    public let body: String
}

/// Thin URLSession JSON client for the TRACE backend. Snake_case ⇄ camelCase and
/// tolerant ISO-8601 date parsing are handled here so DTOs stay plain.
public struct TraceAPIClient: Sendable {
    public let baseURL: URL
    public let tokens: TokenStore
    private let session: URLSession

    public init(baseURL: URL, tokens: TokenStore, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.tokens = tokens
        self.session = session
    }

    // MARK: - Coders

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { dec in
            let s = try dec.singleValueContainer().decode(String.self)
            if let date = parseDate(s) { return date }
            throw DecodingError.dataCorrupted(
                .init(codingPath: dec.codingPath, debugDescription: "unparseable date: \(s)")
            )
        }
        return d
    }()

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    /// Parses ISO-8601 with or without (3- or 6-digit) fractional seconds — Pydantic emits microseconds.
    private static func parseDate(_ s: String) -> Date? {
        let frac = ISO8601DateFormatter()
        frac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        if let d = frac.date(from: s) ?? plain.date(from: s) { return d }

        // Truncate microseconds → milliseconds, then retry.
        guard let dot = s.firstIndex(of: ".") else { return nil }
        var i = s.index(after: dot)
        var digits = ""
        while i < s.endIndex, s[i].isNumber {
            digits.append(s[i])
            i = s.index(after: i)
        }
        let rest = String(s[i...])
        let head = String(s[..<dot])
        let millis = String(digits.prefix(3))
        return frac.date(from: "\(head).\(millis)\(rest)") ?? plain.date(from: head + rest)
    }

    // MARK: - URL building

    private func url(for path: String, query: [URLQueryItem]) -> URL {
        var base = baseURL.absoluteString
        if base.hasSuffix("/") { base.removeLast() }
        var comps = URLComponents(string: base + "/" + path)!
        if !query.isEmpty { comps.queryItems = query }
        return comps.url!
    }

    public func photoURL(for ref: String) -> URL? {
        var base = baseURL.absoluteString
        if base.hasSuffix("/") { base.removeLast() }
        return URL(string: base + "/photos/" + ref)
    }

    // MARK: - Requests

    private func request(_ method: String, _ path: String,
                         query: [URLQueryItem], authed: Bool) async -> URLRequest {
        var req = URLRequest(url: url(for: path, query: query))
        req.httpMethod = method
        if authed, let tok = await tokens.token() {
            req.setValue("Bearer \(tok)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    private func send<T: Decodable>(_ req: URLRequest, as type: T.Type) async throws -> T {
        let (data, resp) = try await session.data(for: req)
        try Self.check(resp, data)
        return try Self.decoder.decode(T.self, from: data)
    }

    private static func check(_ resp: URLResponse, _ data: Data) throws {
        guard let http = resp as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }
    }

    public func get<T: Decodable>(_ path: String, query: [URLQueryItem] = [],
                                  authed: Bool = false) async throws -> T {
        let req = await request("GET", path, query: query, authed: authed)
        return try await send(req, as: T.self)
    }

    public func post<T: Decodable, B: Encodable>(_ path: String, body: B,
                                                 authed: Bool = true) async throws -> T {
        var req = await request("POST", path, query: [], authed: authed)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try Self.encoder.encode(body)
        return try await send(req, as: T.self)
    }

    public func postVoid<B: Encodable>(_ path: String, body: B, authed: Bool = true) async throws {
        var req = await request("POST", path, query: [], authed: authed)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try Self.encoder.encode(body)
        let (data, resp) = try await session.data(for: req)
        try Self.check(resp, data)
    }

    public func uploadPhoto(_ data: Data, filename: String) async throws -> PhotoDTO {
        let boundary = "trace-\(UUID().uuidString)"
        var req = await request("POST", "photos", query: [], authed: true)
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let safeName = filename.replacingOccurrences(of: "/", with: "_")
        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(safeName).jpg\"\r\n")
        body.appendString("Content-Type: image/jpeg\r\n\r\n")
        body.append(data)
        body.appendString("\r\n--\(boundary)--\r\n")
        req.httpBody = body

        return try await send(req, as: PhotoDTO.self)
    }
}

private extension Data {
    mutating func appendString(_ s: String) { append(Data(s.utf8)) }
}
