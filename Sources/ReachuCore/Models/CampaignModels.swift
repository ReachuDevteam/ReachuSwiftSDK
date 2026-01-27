import Foundation

// MARK: - Campaign Models

/// Campaign lifecycle state
public enum CampaignState: String, Codable {
    case upcoming  // Before startDate
    case active    // Between startDate and endDate
    case ended     // After endDate
}

/// Campaign model
public struct Campaign: Codable, Identifiable, Equatable {
    public let id: Int
    public let startDate: String?  // ISO 8601 timestamp
    public let endDate: String?    // ISO 8601 timestamp
    public let isPaused: Bool?     // Campaign paused state (independent of dates)
    public let campaignLogo: String?  // Sponsor logo URL from campaign
    
    public init(id: Int, startDate: String? = nil, endDate: String? = nil, isPaused: Bool? = nil, campaignLogo: String? = nil) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.isPaused = isPaused
        self.campaignLogo = campaignLogo
    }
    
    // Custom decoder to handle isPaused as both String and Bool
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        campaignLogo = try container.decodeIfPresent(String.self, forKey: .campaignLogo)
        
        // Handle isPaused as either String or Bool
        if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: .isPaused) {
            isPaused = boolValue
        } else if let stringValue = try? container.decodeIfPresent(String.self, forKey: .isPaused) {
            // Convert string "true"/"false" to Bool
            isPaused = stringValue.lowercased() == "true"
        } else {
            isPaused = nil
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case startDate
        case endDate
        case isPaused
        case campaignLogo
    }
    
    /// Determine current state based on dates
    /// Handles special cases:
    /// - No dates: Always active (legacy behavior)
    /// - Only startDate: Active after start, never ends
    /// - Only endDate: Active until endDate
    /// - Both dates: Respects both start and end
    public var currentState: CampaignState {
        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Parse dates if available
        let start = startDate.flatMap { formatter.date(from: $0) }
        let end = endDate.flatMap { formatter.date(from: $0) }
        
        // Special case: No dates set - campaign is always active (legacy behavior)
        if start == nil && end == nil {
            return .active
        }
        
        // Special case: Only endDate - campaign is active until endDate
        if start == nil, let end = end {
            return now > end ? .ended : .active
        }
        
        // Special case: Only startDate - campaign becomes active after start, never ends
        if end == nil, let start = start {
            return now < start ? .upcoming : .active
        }
        
        // Normal case: Both dates present
        if let start = start, let end = end {
            if now < start {
                return .upcoming
            } else if now > end {
                return .ended
            } else {
                return .active
            }
        }
        
        // Fallback: Default to active
        return .active
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: Campaign, rhs: Campaign) -> Bool {
        return lhs.id == rhs.id &&
               lhs.startDate == rhs.startDate &&
               lhs.endDate == rhs.endDate &&
               lhs.isPaused == rhs.isPaused &&
               lhs.campaignLogo == rhs.campaignLogo
    }
}

/// SDK Config Response from GET /v1/sdk/config
internal struct SDKConfigResponse: Codable {
    let campaignId: Int
    let campaignName: String?
    let campaignLogo: String?
    let channelId: Int?
    let channelName: String?
    let environment: String?
    let campaigns: CampaignsConfig?
    let marketFallback: MarketFallbackConfig?
    let features: FeaturesConfig?
    
    struct CampaignsConfig: Codable {
        let webSocketBaseURL: String?
        let restAPIBaseURL: String?
    }
    
    struct MarketFallbackConfig: Codable {
        let countryCode: String?
        let currencyCode: String?
        let currencySymbol: String?
        let phoneCode: String?
    }
    
    struct FeaturesConfig: Codable {
        let enableWebSocket: Bool?
        let enableGuestCheckout: Bool?
    }
}

/// Offers Response from GET /v1/offers
internal struct OffersResponse: Codable {
    let campaignId: Int
    let campaignName: String?
    let campaignLogo: String?
    let channelId: Int?
    let channelName: String?
    let offers: [OfferResponse]
}

/// Individual offer/component from offers response
internal struct OfferResponse: Codable {
    let id: String
    let type: String
    let name: String
    let config: [String: AnyCodable]
    let placement: String?
}

/// Backend response wrapper for GET /api/campaigns/:campaignId/components (Legacy)
/// Backend sends: { "components": [...] }
internal struct ComponentsResponseWrapper: Codable {
    let components: [ComponentResponse]
}

/// Backend response model for campaign components
/// This is the actual structure returned by the API
internal struct ComponentResponse: Codable {
    let id: Int
    let campaignId: Int
    let componentId: String
    let status: String
    internal let customConfig: [String: AnyCodable]?
    internal let component: ComponentData?
    
    struct ComponentData: Codable {
        let id: String
        let type: String
        let name: String
        let config: [String: AnyCodable]
    }
}

/// Helper type to decode arbitrary JSON values
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode AnyCodable")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Cannot encode AnyCodable"))
        }
    }
}

/// Component model for dynamic campaign components
/// Uses ComponentConfig from OfferBannerModels for compatibility
public struct Component: Codable, Identifiable {
    public let id: String
    public let type: String  // "banner", "offer_banner", "countdown", etc.
    public let name: String
    public let config: ComponentConfig
    public let status: String?  // "active" or "inactive"
    
    public init(id: String, type: String, name: String, config: ComponentConfig, status: String? = nil) {
        self.id = id
        self.type = type
        self.name = name
        self.config = config
        self.status = status
    }
    
    public var isActive: Bool {
        return status == "active"
    }
    
    /// Decode from backend response format
    init(from response: ComponentResponse) throws {
        // Use componentId as the id (it's the template ID)
        self.id = response.componentId
        
        // Get type and name from nested component, or use defaults
        guard let componentData = response.component else {
            throw DecodingError.keyNotFound(
                CodingKeys.component,
                DecodingError.Context(codingPath: [], debugDescription: "Component data is missing")
            )
        }
        
        self.type = componentData.type
        self.name = componentData.name
        self.status = response.status
        
        // Use customConfig if available, otherwise use component.config
        let configToUse: [String: AnyCodable]
        if let customConfig = response.customConfig, !customConfig.isEmpty {
            configToUse = customConfig
        } else {
            configToUse = componentData.config
        }
        
        // Convert [String: AnyCodable] to JSON Data and decode as ComponentConfig
        let jsonData = try JSONSerialization.data(withJSONObject: configToUse.mapValues { $0.value })
        self.config = try JSONDecoder().decode(ComponentConfig.self, from: jsonData)
    }
    
    /// Decode from JSON (for WebSocket events)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        config = try container.decode(ComponentConfig.self, forKey: .config)
        status = try container.decodeIfPresent(String.self, forKey: .status)
    }
    
    /// Encode to JSON (for WebSocket events)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode(config, forKey: .config)
        try container.encodeIfPresent(status, forKey: .status)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case name
        case config
        case status
        case component
    }
}

// MARK: - WebSocket Event Models

/// Base WebSocket event structure
public struct CampaignWebSocketEvent: Codable {
    public let type: String
    public let campaignId: Int
    
    public init(type: String, campaignId: Int) {
        self.type = type
        self.campaignId = campaignId
    }
}

/// Campaign started event
public struct CampaignStartedEvent: Codable {
    public let type: String
    public let campaignId: Int
    public let startDate: String?
    public let endDate: String?
    
    public init(type: String = "campaign_started", campaignId: Int, startDate: String? = nil, endDate: String? = nil) {
        self.type = type
        self.campaignId = campaignId
        self.startDate = startDate
        self.endDate = endDate
    }
}

/// Campaign ended event
public struct CampaignEndedEvent: Codable {
    public let type: String
    public let campaignId: Int
    public let endDate: String?
    
    public init(type: String = "campaign_ended", campaignId: Int, endDate: String? = nil) {
        self.type = type
        self.campaignId = campaignId
        self.endDate = endDate
    }
}

/// Campaign paused event
public struct CampaignPausedEvent: Codable {
    public let type: String
    public let campaignId: Int
    
    public init(type: String = "campaign_paused", campaignId: Int) {
        self.type = type
        self.campaignId = campaignId
    }
}

/// Campaign resumed event
public struct CampaignResumedEvent: Codable {
    public let type: String
    public let campaignId: Int
    
    public init(type: String = "campaign_resumed", campaignId: Int) {
        self.type = type
        self.campaignId = campaignId
    }
}

/// Component status changed event
/// Supports two formats:
/// 1. New format: { "type": "component_status_changed", "data": { "componentId": 8, "campaignComponentId": 15, "componentType": "product_banner", "status": "active", "config": {...} } }
/// 2. Legacy format: { "type": "component_status_changed", "campaignId": 14, "componentId": "product-banner-template", "status": "inactive", "component": {...} }
public struct ComponentStatusChangedEvent: Codable {
    public let type: String
    public let data: ComponentStatusData?
    
    // Legacy format fields
    public let campaignId: Int?
    public let componentId: String?  // Legacy: string ID
    public let status: String?  // Legacy: status at root level
    public let component: LegacyComponentData?  // Legacy: component object
    
    public struct ComponentStatusData: Codable {
        public let componentId: Int  // Template component ID
        public let campaignComponentId: Int  // Campaign-specific component ID
        public let componentType: String  // "product_banner", "product_carousel", etc.
        public let status: String  // "active" or "inactive"
        public let config: [String: AnyCodable]  // Already merged config (customConfig + defaults)
    }
    
    public struct LegacyComponentData: Codable {
        public let id: String
        public let type: String
        public let name: String
        public let config: [String: AnyCodable]
    }
    
    public init(type: String = "component_status_changed", data: ComponentStatusData? = nil, campaignId: Int? = nil, componentId: String? = nil, status: String? = nil, component: LegacyComponentData? = nil) {
        self.type = type
        self.data = data
        self.campaignId = campaignId
        self.componentId = componentId
        self.status = status
        self.component = component
    }
    
    /// Helper to convert to Component model
    public func toComponent() throws -> Component {
        // Try new format first
        if let data = data {
            let jsonData = try JSONSerialization.data(withJSONObject: data.config.mapValues { $0.value })
            let componentConfig = try JSONDecoder().decode(ComponentConfig.self, from: jsonData)
            
            return Component(
                id: String(data.campaignComponentId),
                type: data.componentType,
                name: "",  // Name not provided in WebSocket event
                config: componentConfig,
                status: data.status
            )
        }
        
        // Fallback to legacy format
        guard let component = component,
              let status = status else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Missing required fields for component_status_changed event"))
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: component.config.mapValues { $0.value })
        let componentConfig = try JSONDecoder().decode(ComponentConfig.self, from: jsonData)
        
        return Component(
            id: component.id,
            type: component.type,
            name: component.name,
            config: componentConfig,
            status: status
        )
    }
}

/// Component config updated event
/// Backend sends two possible formats:
/// 1. { "type": "component_config_updated", "data": { "componentId": 8, "campaignComponentId": 15, "componentType": "product_banner", "config": {...} } }
/// 2. { "type": "component_config_updated", "campaignId": 14, "componentId": "product-banner-template", "component": { "id": "...", "type": "...", "name": "...", "config": {...} } }
public struct ComponentConfigUpdatedEvent: Codable {
    public let type: String
    public let campaignId: Int?
    public let componentId: String?  // String format (new format)
    public let data: ComponentConfigData?  // Old format
    public let component: Component?  // New format (direct Component object)
    
    public struct ComponentConfigData: Codable {
        public let componentId: Int  // Template component ID (old format)
        public let campaignComponentId: Int  // Campaign-specific component ID (old format)
        public let componentType: String  // "product_banner", "product_carousel", etc. (old format)
        public let config: [String: AnyCodable]  // New merged config (old format)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try container.decode(String.self, forKey: .type)
        campaignId = try container.decodeIfPresent(Int.self, forKey: .campaignId)
        componentId = try container.decodeIfPresent(String.self, forKey: .componentId)
        
        // Try new format first (with direct component)
        if container.contains(.component) {
            component = try container.decode(Component.self, forKey: .component)
            data = nil
        }
        // Fallback to old format (with data wrapper)
        else if container.contains(.data) {
            data = try container.decode(ComponentConfigData.self, forKey: .data)
            component = nil
        } else {
            data = nil
            component = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(campaignId, forKey: .campaignId)
        try container.encodeIfPresent(componentId, forKey: .componentId)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(component, forKey: .component)
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, campaignId, componentId, data, component
    }
    
    /// Helper to convert to Component model (handles both formats)
    public func toComponent() throws -> Component {
        // New format: direct Component object
        if let component = component {
            return component
        }
        
        // Old format: convert from ComponentConfigData
        guard let data = data else {
            throw DecodingError.keyNotFound(
                CodingKeys.component,
                DecodingError.Context(codingPath: [], debugDescription: "Neither component nor data found in ComponentConfigUpdatedEvent")
            )
        }
        
        // Convert config dictionary to ComponentConfig
        let jsonData = try JSONSerialization.data(withJSONObject: data.config.mapValues { $0.value })
        let componentConfig = try JSONDecoder().decode(ComponentConfig.self, from: jsonData)
        
        return Component(
            id: String(data.campaignComponentId),
            type: data.componentType,
            name: "",  // Name not provided in old format
            config: componentConfig,
            status: "active"  // Config updates are always for active components
        )
    }
}


