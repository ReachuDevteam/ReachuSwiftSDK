import Foundation

// MARK: - Campaign Models

/// Campaign lifecycle state
public enum CampaignState: String, Codable {
    case upcoming  // Before startDate
    case active    // Between startDate and endDate
    case ended     // After endDate
}

/// Campaign model
public struct Campaign: Codable, Identifiable {
    public let id: Int
    public let startDate: String?  // ISO 8601 timestamp
    public let endDate: String?    // ISO 8601 timestamp
    public let isPaused: Bool?     // Campaign paused state (independent of dates)
    
    public init(id: Int, startDate: String? = nil, endDate: String? = nil, isPaused: Bool? = nil) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.isPaused = isPaused
    }
    
    // Custom decoder to handle isPaused as both String and Bool
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        
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
public struct ComponentStatusChangedEvent: Codable {
    public let type: String
    public let campaignId: Int
    public let componentId: String
    public let status: String  // "active" or "inactive"
    public let component: Component?
    
    public init(type: String = "component_status_changed", campaignId: Int, componentId: String, status: String, component: Component? = nil) {
        self.type = type
        self.campaignId = campaignId
        self.componentId = componentId
        self.status = status
        self.component = component
    }
}

/// Component config updated event
public struct ComponentConfigUpdatedEvent: Codable {
    public let type: String
    public let campaignId: Int
    public let componentId: String
    public let component: Component
    
    public init(type: String = "component_config_updated", campaignId: Int, componentId: String, component: Component) {
        self.type = type
        self.campaignId = campaignId
        self.componentId = componentId
        self.component = component
    }
}


