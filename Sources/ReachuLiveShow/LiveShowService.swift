import Foundation

public final class LiveShowService {
    public struct RefreshResponse: Decodable {
        public let hls: String?
    }

    public struct RequestBody: Encodable {
        public let streamId: String?
        public let referer: String?
    }

    private let configuration: ReachuLiveShowPlayer.Configuration
    private let session: URLSession

    public init(configuration: ReachuLiveShowPlayer.Configuration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    public func configurationHeaders() -> [String: String]? {
        configuration.mediaRequestHeaders
    }

    public func refreshHLS(streamId: String?) async throws -> URL? {
        var request = URLRequest(url: configuration.refreshHLSEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = configuration.apiKey, !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        }
        let referer = configuration.mediaRequestHeaders?["Referer"]
        request.httpBody = try JSONEncoder().encode(RequestBody(streamId: streamId, referer: referer))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { return nil }
        guard 200..<300 ~= http.statusCode else {
            print(""); return nil
            //throw NetworkError("Refresh HLS failed", status: http.statusCode, details: "")
        }
        let decoded = try JSONDecoder().decode(RefreshResponse.self, from: data)
        if let hlsString = decoded.hls, let url = URL(string: hlsString) {
            return url
        }
        return nil
    }
}


