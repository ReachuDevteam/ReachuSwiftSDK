import Foundation
import ReachuCore

public enum DynamicComponentsAPIError: Error {
    case invalidResponse
    case decodingFailed
    case network(Error)
}

public struct DynamicComponentsAPI {
    public let baseURL: URL
    
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    public func fetchComponents(campaignId: String) async throws -> [DynamicComponent] {
        let url = baseURL.appendingPathComponent("api/components/\(campaignId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw DynamicComponentsAPIError.invalidResponse
            }
            return try BackendMapper.mapComponents(from: data)
        } catch {
            throw DynamicComponentsAPIError.network(error)
        }
    }
}

enum BackendMapper {
    static func mapComponents(from data: Data) throws -> [DynamicComponent] {
        let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        guard let array = json else { throw DynamicComponentsAPIError.decodingFailed }
        return array.compactMap { mapComponent($0) }
    }
    
    private static func mapComponent(_ dict: [String: Any]) -> DynamicComponent? {
        guard let id = dict["id"] as? String,
              let typeStr = dict["type"] as? String,
              let data = dict["data"] as? [String: Any]
        else { return nil }
        
        let type = mapType(typeStr)
        let position = mapPosition((data["position"] as? String) ?? (data["position"] as? String) ?? "overlay")
        let startTime = isoDate((data["startTime"] as? String))
        let endTime = isoDate((data["endTime"] as? String))
        
        var payload: [String: String] = [:]
        
        switch type {
        case .productSpotlight:
            if let productDict = data["product"] as? [String: Any] {
                payload["productId"] = String((productDict["id"] as? Int) ?? 0)
                if let title = productDict["title"] as? String { payload["title"] = title }
                if let images = productDict["images"] as? [[String: Any]], let first = images.first, let url = first["url"] as? String {
                    payload["image"] = url
                }
            }
        case .banner:
            if let title = data["title"] as? String { payload["title"] = title }
            if let text = data["text"] as? String { payload["message"] = text }
        default:
            break
        }
        
        return DynamicComponent(
            id: id,
            type: type,
            startTime: startTime,
            endTime: endTime,
            position: position,
            priority: 0,
            payload: payload.isEmpty ? nil : payload
        )
    }
    
    private static func mapType(_ raw: String) -> DynamicComponentType {
        switch raw {
        case "featured_product": return .productSpotlight
        case "banner": return .banner
        case "poll": return .poll
        case "countdown": return .countdown
        default: return .banner
        }
    }
    
    private static func mapPosition(_ raw: String) -> DynamicComponentPosition {
        switch raw {
        case "top": return .top
        case "bottom": return .bottom
        case "left", "leading": return .leading
        case "right", "trailing": return .trailing
        case "center": return .center
        default: return .overlay
        }
    }
    
    private static func isoDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: raw) ?? ISO8601DateFormatter().date(from: raw)
    }
}


