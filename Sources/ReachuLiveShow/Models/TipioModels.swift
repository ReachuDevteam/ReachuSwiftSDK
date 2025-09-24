import Foundation
import ReachuCore

// MARK: - Tipio API Models

/// Response from Tipio API when fetching a livestream by ID
public struct TipioLiveStream: Identifiable, Codable {
    public let id: Int
    public let title: String
    public let liveStreamId: String  // Vimeo live event ID
    public let hls: String?          // HLS stream URL (null at beginning)
    public let player: String?       // Vimeo player URL (written at end)
    public let thumbnail: String?    // Thumbnail image URL
    public let broadcasting: Bool    // Is currently broadcasting
    public let date: Date           // Start date
    public let endDate: Date        // End date
    public let streamDone: Bool?    // Stream completion status (null at beginning)
    public let videoId: String?     // Final video ID (written at end)
    
    enum CodingKeys: String, CodingKey {
        case id, title, liveStreamId, hls, player, thumbnail, broadcasting, date, streamDone, videoId
        case endDate = "end_date"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        liveStreamId = try container.decode(String.self, forKey: .liveStreamId)
        hls = try container.decodeIfPresent(String.self, forKey: .hls)
        player = try container.decodeIfPresent(String.self, forKey: .player)
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        broadcasting = try container.decode(Bool.self, forKey: .broadcasting)
        streamDone = try container.decodeIfPresent(Bool.self, forKey: .streamDone)
        videoId = try container.decodeIfPresent(String.self, forKey: .videoId)
        
        // Parse dates
        let dateFormatter = ISO8601DateFormatter()
        let dateString = try container.decode(String.self, forKey: .date)
        let endDateString = try container.decode(String.self, forKey: .endDate)
        
        guard let parsedDate = dateFormatter.date(from: dateString),
              let parsedEndDate = dateFormatter.date(from: endDateString) else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Invalid date format")
        }
        
        date = parsedDate
        endDate = parsedEndDate
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(liveStreamId, forKey: .liveStreamId)
        try container.encodeIfPresent(hls, forKey: .hls)
        try container.encodeIfPresent(player, forKey: .player)
        try container.encodeIfPresent(thumbnail, forKey: .thumbnail)
        try container.encode(broadcasting, forKey: .broadcasting)
        try container.encodeIfPresent(streamDone, forKey: .streamDone)
        try container.encodeIfPresent(videoId, forKey: .videoId)
        
        // Encode dates
        let dateFormatter = ISO8601DateFormatter()
        try container.encode(dateFormatter.string(from: date), forKey: .date)
        try container.encode(dateFormatter.string(from: endDate), forKey: .endDate)
    }
}

// MARK: - Tipio WebSocket Events

/// WebSocket event types from Tipio
public enum TipioEventType: String, Codable {
    case streamStarted = "stream_started"
    case streamEnded = "stream_ended"
    case streamStatusChanged = "stream_status_changed"
    case chatMessage = "chat_message"
    case viewerCountChanged = "viewer_count_changed"
    case productHighlighted = "product_highlighted"
    case componentActivated = "component_activated"
    case componentDeactivated = "component_deactivated"
}

/// WebSocket event from Tipio
public struct TipioEvent: Codable {
    public let type: TipioEventType
    public let streamId: Int
    public let timestamp: Date
    public let data: TipioEventData
    
    public init(type: TipioEventType, streamId: Int, timestamp: Date = Date(), data: TipioEventData) {
        self.type = type
        self.streamId = streamId
        self.timestamp = timestamp
        self.data = data
    }
}

/// Event data payload
public enum TipioEventData: Codable {
    case streamStatus(TipioStreamStatusData)
    case chatMessage(TipioChatMessageData)
    case viewerCount(TipioViewerCountData)
    case productHighlight(TipioProductHighlightData)
    case component(TipioComponentData)
    
    enum CodingKeys: String, CodingKey {
        case type
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "stream_status":
            self = .streamStatus(try TipioStreamStatusData(from: decoder))
        case "chat_message":
            self = .chatMessage(try TipioChatMessageData(from: decoder))
        case "viewer_count":
            self = .viewerCount(try TipioViewerCountData(from: decoder))
        case "product_highlight":
            self = .productHighlight(try TipioProductHighlightData(from: decoder))
        case "component":
            self = .component(try TipioComponentData(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown event type: \(type)")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .streamStatus(let data):
            try data.encode(to: encoder)
        case .chatMessage(let data):
            try data.encode(to: encoder)
        case .viewerCount(let data):
            try data.encode(to: encoder)
        case .productHighlight(let data):
            try data.encode(to: encoder)
        case .component(let data):
            try data.encode(to: encoder)
        }
    }
}

// MARK: - Event Data Types

public struct TipioStreamStatusData: Codable {
    public let broadcasting: Bool
    public let hlsUrl: String?
    public let playerUrl: String?
    public let videoId: String?
    
    enum CodingKeys: String, CodingKey {
        case broadcasting
        case hlsUrl = "hls"
        case playerUrl = "player"
        case videoId
    }
}

public struct TipioChatMessageData: Codable {
    public let id: String
    public let userId: String
    public let username: String
    public let message: String
    public let timestamp: Date
    public let isStreamer: Bool
    public let avatarUrl: String?
}

public struct TipioViewerCountData: Codable {
    public let count: Int
    public let activeViewers: Int
}

public struct TipioProductHighlightData: Codable {
    public let productId: String
    public let duration: TimeInterval
    public let position: String? // Position on screen
}

public struct TipioComponentData: Codable {
    public let componentId: String
    public let type: String
    public let active: Bool
    public let config: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case componentId, type, active, config
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        componentId = try container.decode(String.self, forKey: .componentId)
        type = try container.decode(String.self, forKey: .type)
        active = try container.decode(Bool.self, forKey: .active)
        
        // Decode config as generic dictionary
        if let configData = try? container.decode([String: String].self, forKey: .config) {
            config = configData
        } else {
            config = [:]
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(componentId, forKey: .componentId)
        try container.encode(type, forKey: .type)
        try container.encode(active, forKey: .active)
        
        // Simple encoding for config
        if let stringConfig = config as? [String: String] {
            try container.encode(stringConfig, forKey: .config)
        }
    }
}

// MARK: - Conversion Extensions

extension TipioLiveStream {
    /// Convert Tipio livestream to Reachu LiveStream model
    public func toLiveStream(
        streamer: LiveStreamer? = nil,
        featuredProducts: [LiveProduct] = [],
        chatMessages: [LiveChatMessage] = []
    ) -> LiveStream {
        let defaultStreamer = streamer ?? LiveStreamer(
            id: "tipio-\(id)",
            name: "Live Host",
            username: "@livehost",
            avatarUrl: thumbnail,
            isVerified: true,
            followerCount: 0
        )
        
        // Use HLS URL if available, otherwise player URL, otherwise construct Vimeo embed
        let videoUrl: String
        if let hls = hls, !hls.isEmpty {
            videoUrl = hls
        } else if let player = player, !player.isEmpty {
            videoUrl = player
        } else {
            // Construct Vimeo embed URL from liveStreamId
            videoUrl = "https://player.vimeo.com/video/\(liveStreamId)"
        }
        
        return LiveStream(
            id: String(id),
            title: title,
            description: nil,
            streamer: defaultStreamer,
            videoUrl: videoUrl,
            thumbnailUrl: thumbnail,
            viewerCount: 0, // Will be updated via WebSocket
            isLive: broadcasting,
            startTime: date,
            endTime: endDate,
            featuredProducts: featuredProducts,
            chatMessages: chatMessages
        )
    }
}

extension TipioChatMessageData {
    /// Convert Tipio chat message to Reachu LiveChatMessage
    public func toLiveChatMessage() -> LiveChatMessage {
        let user = LiveChatUser(
            id: userId,
            username: username,
            avatarUrl: avatarUrl,
            isVerified: false,
            isModerator: isStreamer
        )
        
        return LiveChatMessage(
            id: id,
            user: user,
            message: message,
            timestamp: timestamp,
            isStreamerMessage: isStreamer,
            isPinned: false,
            reactions: []
        )
    }
}

// MARK: - API Response Types

/// Response wrapper for Tipio API calls
public struct TipioApiResponse<T: Codable>: Codable {
    public let success: Bool
    public let data: T?
    public let error: TipioApiError?
    public let message: String?
}

/// Tipio API error structure
public struct TipioApiError: Codable, LocalizedError {
    public let code: String
    public let message: String
    
    public var errorDescription: String? {
        return message
    }
}

/// Status response for stream operations
public struct TipioStatusResponse: Codable {
    public let streamId: Int
    public let status: String
    public let timestamp: Date
}
