import Foundation

/// Cache Manager for persisting campaign and component data
/// Provides fast initial load by reading from disk cache
/// Automatically updates cache when data changes via WebSocket
@MainActor
public class CacheManager {
    
    // MARK: - Singleton
    public static let shared = CacheManager()
    
    // MARK: - Cache Keys
    private enum CacheKeys {
        static let campaign = "reachu.cache.campaign"
        static let components = "reachu.cache.components"
        static let campaignState = "reachu.cache.campaignState"
        static let isCampaignActive = "reachu.cache.isCampaignActive"
        static let lastUpdated = "reachu.cache.lastUpdated"
    }
    
    // MARK: - Cache Expiration
    /// Cache expiration time in seconds (default: 24 hours)
    public var cacheExpirationInterval: TimeInterval = 24 * 60 * 60
    
    private let userDefaults: UserDefaults
    
    // MARK: - Initialization
    private init() {
        self.userDefaults = UserDefaults.standard
    }
    
    // MARK: - Campaign Cache
    
    /// Save campaign to cache
    public func saveCampaign(_ campaign: Campaign) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(campaign)
            userDefaults.set(data, forKey: CacheKeys.campaign)
            userDefaults.set(Date(), forKey: CacheKeys.lastUpdated)
            ReachuLogger.debug("Campaign cached: ID \(campaign.id)", component: "CacheManager")
        } catch {
            ReachuLogger.error("Failed to cache campaign: \(error)", component: "CacheManager")
        }
    }
    
    /// Load campaign from cache
    /// - Returns: Cached campaign if available and not expired, nil otherwise
    public func loadCampaign() -> Campaign? {
        guard let data = userDefaults.data(forKey: CacheKeys.campaign),
              isCacheValid() else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let campaign = try decoder.decode(Campaign.self, from: data)
            ReachuLogger.debug("Campaign loaded from cache: ID \(campaign.id)", component: "CacheManager")
            return campaign
        } catch {
            ReachuLogger.error("Failed to decode cached campaign: \(error)", component: "CacheManager")
            return nil
        }
    }
    
    /// Save campaign state to cache
    public func saveCampaignState(_ state: CampaignState, isActive: Bool) {
        do {
            let encoder = JSONEncoder()
            let stateData = try encoder.encode(state)
            userDefaults.set(stateData, forKey: CacheKeys.campaignState)
            userDefaults.set(isActive, forKey: CacheKeys.isCampaignActive)
            userDefaults.set(Date(), forKey: CacheKeys.lastUpdated)
            ReachuLogger.debug("Campaign state cached: \(state.rawValue), active: \(isActive)", component: "CacheManager")
        } catch {
            ReachuLogger.error("Failed to cache campaign state: \(error)", component: "CacheManager")
        }
    }
    
    /// Load campaign state from cache
    /// - Returns: Tuple of (state, isActive) if available and not expired, nil otherwise
    public func loadCampaignState() -> (state: CampaignState, isActive: Bool)? {
        guard isCacheValid(),
              let stateData = userDefaults.data(forKey: CacheKeys.campaignState) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let state = try decoder.decode(CampaignState.self, from: stateData)
            let isActive = userDefaults.bool(forKey: CacheKeys.isCampaignActive)
            ReachuLogger.debug("Campaign state loaded from cache: \(state.rawValue), active: \(isActive)", component: "CacheManager")
            return (state, isActive)
        } catch {
            ReachuLogger.error("Failed to decode cached campaign state: \(error)", component: "CacheManager")
            return nil
        }
    }
    
    // MARK: - Components Cache
    
    /// Save components to cache
    public func saveComponents(_ components: [Component]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(components)
            userDefaults.set(data, forKey: CacheKeys.components)
            userDefaults.set(Date(), forKey: CacheKeys.lastUpdated)
            ReachuLogger.debug("Cached \(components.count) components", component: "CacheManager")
        } catch {
            ReachuLogger.error("Failed to cache components: \(error)", component: "CacheManager")
        }
    }
    
    /// Load components from cache
    /// - Returns: Cached components if available and not expired, empty array otherwise
    public func loadComponents() -> [Component] {
        guard let data = userDefaults.data(forKey: CacheKeys.components),
              isCacheValid() else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let components = try decoder.decode([Component].self, from: data)
            ReachuLogger.debug("Loaded \(components.count) components from cache", component: "CacheManager")
            return components
        } catch {
            ReachuLogger.error("Failed to decode cached components: \(error)", component: "CacheManager")
            return []
        }
    }
    
    // MARK: - Cache Validation
    
    /// Check if cache is still valid (not expired)
    private func isCacheValid() -> Bool {
        guard let lastUpdated = userDefaults.object(forKey: CacheKeys.lastUpdated) as? Date else {
            return false
        }
        
        let age = Date().timeIntervalSince(lastUpdated)
        let isValid = age < cacheExpirationInterval
        
        if !isValid {
            ReachuLogger.debug("Cache expired (age: \(Int(age))s, max: \(Int(cacheExpirationInterval))s)", component: "CacheManager")
        }
        
        return isValid
    }
    
    /// Clear all cached data
    public func clearCache() {
        userDefaults.removeObject(forKey: CacheKeys.campaign)
        userDefaults.removeObject(forKey: CacheKeys.components)
        userDefaults.removeObject(forKey: CacheKeys.campaignState)
        userDefaults.removeObject(forKey: CacheKeys.isCampaignActive)
        userDefaults.removeObject(forKey: CacheKeys.lastUpdated)
        ReachuLogger.info("Cache cleared", component: "CacheManager")
    }
    
    /// Clear cache for a specific campaign (useful when switching campaigns)
    public func clearCacheForCampaign(campaignId: Int) {
        // Check if cached campaign matches
        if let cachedCampaign = loadCampaign(), cachedCampaign.id == campaignId {
            clearCache()
            ReachuLogger.debug("Cleared cache for campaign \(campaignId)", component: "CacheManager")
        }
    }
    
    /// Get cache age in seconds
    public func getCacheAge() -> TimeInterval? {
        guard let lastUpdated = userDefaults.object(forKey: CacheKeys.lastUpdated) as? Date else {
            return nil
        }
        return Date().timeIntervalSince(lastUpdated)
    }
    
    /// Check if cache exists (regardless of expiration)
    public func hasCache() -> Bool {
        return userDefaults.object(forKey: CacheKeys.lastUpdated) != nil
    }
}

