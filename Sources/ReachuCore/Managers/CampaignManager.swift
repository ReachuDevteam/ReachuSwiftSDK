import Foundation
import Combine

/// Global Campaign Manager for handling campaign lifecycle
/// Manages campaign states, WebSocket connections, and component visibility
@MainActor
public class CampaignManager: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = CampaignManager()
    
    // MARK: - Published Properties
    @Published public private(set) var isCampaignActive: Bool = true  // Default to true (no campaign restrictions)
    @Published public private(set) var campaignState: CampaignState = .active
    @Published public private(set) var activeComponents: [Component] = []
    @Published public private(set) var isConnected: Bool = false
    @Published public private(set) var currentCampaign: Campaign?
    
    // MARK: - Private Properties
    private var campaignId: Int?
    private var webSocketManager: CampaignWebSocketManager?
    private var cancellables = Set<AnyCancellable>()
    private var baseURL: String  // For REST API (GraphQL base URL)
    private var isInitializing = false  // Flag to prevent multiple simultaneous initializations
    
    // Campaign endpoints from configuration
    private var campaignWebSocketBaseURL: String {
        ReachuConfiguration.shared.campaignConfiguration.webSocketBaseURL
    }
    
    private var campaignRestAPIBaseURL: String {
        ReachuConfiguration.shared.campaignConfiguration.restAPIBaseURL
    }
    
    // MARK: - Initialization
    private init() {
        // Get base URL from configuration
        let config = ReachuConfiguration.shared
        self.baseURL = config.environment.graphQLURL
            .replacingOccurrences(of: "/graphql", with: "")
            .replacingOccurrences(of: "/v1/graphql", with: "")
        
        // Initialize with campaignId from configuration
        let configuredCampaignId = config.liveShowConfiguration.campaignId
        
        // If campaignId is 0 or not configured, campaigns are disabled (normal SDK behavior)
        if configuredCampaignId > 0 {
            self.campaignId = configuredCampaignId
            Task {
                await initializeCampaign()
            }
        } else {
            // No campaign configured - SDK works normally without restrictions
            self.isCampaignActive = true
            self.campaignState = .active
        }
    }
    
    // MARK: - Public Methods
    
    /// Reinitialize campaign manager with current configuration
    /// Called automatically when ReachuConfiguration is updated
    public func reinitialize() {
        // Disconnect existing connection
        disconnect()
        
        // Get current configuration
        let config = ReachuConfiguration.shared
        let configuredCampaignId = config.liveShowConfiguration.campaignId
        
        // Update base URL
        self.baseURL = config.environment.graphQLURL
            .replacingOccurrences(of: "/graphql", with: "")
            .replacingOccurrences(of: "/v1/graphql", with: "")
        
        // If campaignId is 0 or not configured, campaigns are disabled (normal SDK behavior)
        if configuredCampaignId > 0 {
            self.campaignId = configuredCampaignId
            Task {
                await initializeCampaign()
            }
        } else {
            // No campaign configured - SDK works normally without restrictions
            self.campaignId = nil
            self.isCampaignActive = true
            self.campaignState = .active
            self.activeComponents.removeAll()
        }
    }
    
    /// Initialize campaign connection (called automatically if campaignId > 0)
    public func initializeCampaign() async {
        guard let campaignId = campaignId, campaignId > 0 else {
            return
        }
        
        // Prevent multiple simultaneous initializations
        guard !isInitializing else {
            // Campaign initialization already in progress, skip
            return
        }
        
        isInitializing = true
        defer { isInitializing = false }
        
        
        // 0. Load from cache first for instant UI update
        loadFromCache()
        
        // 1. Fetch campaign info and determine initial state
        await fetchCampaignInfo(campaignId: campaignId)
        
        // 2. Connect WebSocket for real-time updates
        // According to backend behavior:
        // - If Ended: Backend sends campaign_ended immediately
        // - If Upcoming: No event sent, waits for campaign_started
        // - If Active: No event sent, can fetch components
        await connectWebSocket(campaignId: campaignId)
        
        // 3. Fetch active components ONLY if campaign is active AND not paused
        // Don't fetch if Upcoming (wait for campaign_started), Ended (already handled), or Paused
        if campaignState == .active && isCampaignActive && currentCampaign?.isPaused != true {
            await fetchActiveComponents(campaignId: campaignId)
        }
    }
    
    /// Check if a component should be displayed based on campaign state
    public func shouldShowComponent(type: String) -> Bool {
        // If no campaign configured, show everything
        guard campaignId != nil && campaignId! > 0 else {
            return true
        }
        
        // Campaign must be active
        guard isCampaignActive else {
            return false
        }
        
        // Check if component type is active
        let component = activeComponents.first { $0.type == type }
        return component?.isActive ?? false
    }
    
    /// Get active component by type
    /// - Parameters:
    ///   - type: Component type (e.g., "product_spotlight", "product_carousel")
    ///   - componentId: Optional component ID to identify a specific component. If nil, returns the first matching component.
    /// - Returns: Active component matching the type and optional componentId, or nil if not found
    public func getActiveComponent(type: String, componentId: String? = nil) -> Component? {
        guard isCampaignActive else { return nil }
        
        if let componentId = componentId {
            // Search by type AND specific componentId
            return activeComponents.first { 
                $0.type == type && $0.id == componentId && $0.isActive 
            }
        } else {
            // Current behavior: return the first one found
            return activeComponents.first { $0.type == type && $0.isActive }
        }
    }
    
    /// Get all active components by type
    public func getActiveComponents(type: String) -> [Component] {
        guard isCampaignActive else { return [] }
        return activeComponents.filter { $0.type == type && $0.isActive }
    }
    
    /// Disconnect from campaign
    public func disconnect() {
        webSocketManager?.disconnect()
        webSocketManager = nil
        isConnected = false
    }
    
    // MARK: - Private Methods
    
    /// Load campaign and components from cache for instant UI update
    private func loadFromCache() {
        // Load campaign
        if let cachedCampaign = CacheManager.shared.loadCampaign() {
            self.currentCampaign = cachedCampaign
            self.campaignState = cachedCampaign.currentState
        }
        
        // Load campaign state
        if let cachedState = CacheManager.shared.loadCampaignState() {
            self.campaignState = cachedState.state
            self.isCampaignActive = cachedState.isActive
        }
        
        // Load components
        let cachedComponents = CacheManager.shared.loadComponents()
        if !cachedComponents.isEmpty {
            self.activeComponents = cachedComponents
        }
        
        if CacheManager.shared.hasCache() {
            let age = CacheManager.shared.getCacheAge() ?? 0
        }
    }
    
    /// Fetch campaign information from API
    private func fetchCampaignInfo(campaignId: Int) async {
        let urlString = "\(campaignRestAPIBaseURL)/api/campaigns/\(campaignId)"
        guard let url = URL(string: urlString) else {
            ReachuLogger.error("Invalid campaign API URL: \(urlString)", component: "CampaignManager")
            return
        }
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add API Key authentication
        let config = ReachuConfiguration.shared
        if !config.apiKey.isEmpty {
            request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                
                if httpResponse.statusCode == 404 {
                    ReachuLogger.warning("Campaign \(campaignId) not found - SDK works normally", component: "CampaignManager")
                    // Campaign not found - allow normal SDK behavior
                    self.isCampaignActive = true
                    self.campaignState = .active
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
                    ReachuLogger.error("Campaign info request failed with status \(httpResponse.statusCode)", component: "CampaignManager")
                    // On error, allow normal SDK behavior
                    self.isCampaignActive = true
                    self.campaignState = .active
                    return
                }
            }
            
            // Validate that we received JSON, not HTML
            if let responseString = String(data: data, encoding: .utf8), responseString.trimmingCharacters(in: .whitespaces).hasPrefix("<") {
                ReachuLogger.error("Received HTML instead of JSON from campaign endpoint", component: "CampaignManager")
                // On error, allow normal SDK behavior
                self.isCampaignActive = true
                self.campaignState = .active
                return
            }
            
            let campaign = try JSONDecoder().decode(Campaign.self, from: data)
            self.currentCampaign = campaign
            self.campaignState = campaign.currentState
            
            // Check if campaign is paused first (takes priority over date-based state)
            if campaign.isPaused == true {
                self.isCampaignActive = false
                self.activeComponents.removeAll()
                // Save to cache
                CacheManager.shared.saveCampaign(campaign)
                CacheManager.shared.saveCampaignState(campaignState, isActive: isCampaignActive)
                CacheManager.shared.saveComponents([])
                return
            }
            
            // Update active state based on campaign state
            switch campaignState {
            case .upcoming:
                self.isCampaignActive = false
            case .active:
                self.isCampaignActive = true
                // Campaign is active
            case .ended:
                self.isCampaignActive = false
                self.activeComponents.removeAll()
                ReachuLogger.warning("Campaign \(campaignId) has ended - hiding all components", component: "CampaignManager")
            }
            
            // Save to cache
            CacheManager.shared.saveCampaign(campaign)
            CacheManager.shared.saveCampaignState(campaignState, isActive: isCampaignActive)
            
        } catch let decodingError as DecodingError {
            ReachuLogger.error("Failed to decode campaign info: \(decodingError)", component: "CampaignManager")
            if let data = try? await URLSession.shared.data(for: request).0,
               let responseString = String(data: data, encoding: .utf8) {
            }
            // On error, allow normal SDK behavior
            self.isCampaignActive = true
            self.campaignState = .active
        } catch {
            ReachuLogger.warning("Failed to fetch campaign info: \(error)", component: "CampaignManager")
            // On error, allow normal SDK behavior
            self.isCampaignActive = true
            self.campaignState = .active
        }
    }
    
    /// Fetch active components from API
    private func fetchActiveComponents(campaignId: Int) async {
        let urlString = "\(campaignRestAPIBaseURL)/api/campaigns/\(campaignId)/components"
        guard let url = URL(string: urlString) else {
            ReachuLogger.error("Invalid components API URL", component: "CampaignManager")
            return
        }
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add API Key authentication
        let config = ReachuConfiguration.shared
        if !config.apiKey.isEmpty {
            request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
        }
        
        var responseData: Data?
        var responseString: String?
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            responseData = data
            responseString = String(data: data, encoding: .utf8)
            
            // Validate HTTP response before decoding
            if let httpResponse = response as? HTTPURLResponse {
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
                    ReachuLogger.error("Components request failed with status \(httpResponse.statusCode)", component: "CampaignManager")
                    
                    // If 404, campaign might not have components configured - this is OK
                    if httpResponse.statusCode == 404 {
                        self.activeComponents = []
                        return
                    }
                    return
                }
            }
            
            // Validate that we received JSON, not HTML
            if let responseString = responseString, responseString.trimmingCharacters(in: .whitespaces).hasPrefix("<") {
                ReachuLogger.error("Received HTML instead of JSON from components endpoint", component: "CampaignManager")
                return
            }
            
            // Log raw JSON response for debugging
            if let responseString = responseString {
            }
            
            guard let data = responseData else {
                ReachuLogger.error("No data received", component: "CampaignManager")
                return
            }
            
            // Decode backend response format
            // Backend sends: { "components": [...] }
            // Try wrapped format first, then fallback to direct array
            let responses: [ComponentResponse]
            do {
                let wrapper = try JSONDecoder().decode(ComponentsResponseWrapper.self, from: data)
                responses = wrapper.components
            } catch {
                // Fallback: try direct array format
                responses = try JSONDecoder().decode([ComponentResponse].self, from: data)
            }
            
            for (index, response) in responses.enumerated() {
                
                if let customConfig = response.customConfig {
                }
                
                if let component = response.component {
                }
            }
            
            // Convert to Component model
            let components = try responses.map { response -> Component in
                
                let component = try Component(from: response)
                
                // Log which config was used
                if let customConfig = response.customConfig, !customConfig.isEmpty {
                } else if response.component != nil {
                }
                
                
                return component
            }
            
            
            // Filter to only active components
            self.activeComponents = components.filter { $0.isActive }
            
            // Components loaded
            if !self.activeComponents.isEmpty {
                ReachuLogger.debug("Active component types: \(self.activeComponents.map { $0.type }.joined(separator: ", "))", component: "CampaignManager")
            }
            
            // Save to cache
            CacheManager.shared.saveComponents(self.activeComponents)
            
        } catch let decodingError as DecodingError {
            ReachuLogger.error("Failed to decode components: \(decodingError)", component: "CampaignManager")
            
            // Log detailed decoding error information
            switch decodingError {
            case .typeMismatch(let type, let context):
                ReachuLogger.error("Type mismatch: Expected \(String(describing: type)), path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", component: "CampaignManager")
            case .valueNotFound(let type, let context):
                ReachuLogger.error("Value not found: \(String(describing: type)), path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", component: "CampaignManager")
            case .keyNotFound(let key, let context):
                ReachuLogger.error("Key not found: \(key.stringValue), path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", component: "CampaignManager")
            case .dataCorrupted(let context):
                ReachuLogger.error("Data corrupted: \(context.debugDescription), path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", component: "CampaignManager")
            @unknown default:
                ReachuLogger.error("Unknown decoding error", component: "CampaignManager")
            }
            
            // Log raw response for debugging
            if let responseString = responseString {
                ReachuLogger.debug("Raw response: \(responseString.prefix(1000))", component: "CampaignManager")
            }
        } catch {
            ReachuLogger.warning("Failed to fetch active components: \(error)", component: "CampaignManager")
            
            // Log raw response for debugging
            if let responseString = responseString {
                ReachuLogger.debug("Raw response: \(responseString.prefix(1000))", component: "CampaignManager")
            }
        }
    }
    
    /// Connect to campaign WebSocket
    /// According to backend behavior:
    /// - If campaign is Ended: Backend sends campaign_ended immediately
    /// - If campaign is Upcoming: No event sent, waits for campaign_started
    /// - If campaign is Active: No event sent, can fetch components
    private func connectWebSocket(campaignId: Int) async {
        // Use the campaign WebSocket endpoint, not the GraphQL endpoint
        webSocketManager = CampaignWebSocketManager(campaignId: campaignId, baseURL: campaignWebSocketBaseURL)
        
        // Setup event handlers
        webSocketManager?.onCampaignStarted = { [weak self] event in
            Task { @MainActor in
                self?.handleCampaignStarted(event)
            }
        }
        
        webSocketManager?.onCampaignEnded = { [weak self] event in
            Task { @MainActor in
                self?.handleCampaignEnded(event)
            }
        }
        
        webSocketManager?.onCampaignPaused = { [weak self] event in
            Task { @MainActor in
                self?.handleCampaignPaused(event)
            }
        }
        
        webSocketManager?.onCampaignResumed = { [weak self] event in
            Task { @MainActor in
                self?.handleCampaignResumed(event)
            }
        }
        
        webSocketManager?.onComponentStatusChanged = { [weak self] event in
            Task { @MainActor in
                self?.handleComponentStatusChanged(event)
            }
        }
        
        webSocketManager?.onComponentConfigUpdated = { [weak self] event in
            Task { @MainActor in
                self?.handleComponentConfigUpdated(event)
            }
        }
        
        webSocketManager?.onConnectionStatusChanged = { [weak self] connected in
            Task { @MainActor in
                self?.isConnected = connected
                
                // According to backend behavior:
                // - If campaign is Ended: Backend sends campaign_ended immediately when connection opens
                // - If campaign is Upcoming: No event sent, waits for campaign_started
                // - If campaign is Active: No event sent, can fetch components
                // The event handlers above will process these events automatically
            }
        }
        
        await webSocketManager?.connect()
    }
    
    // MARK: - Event Handlers
    
    private func handleCampaignStarted(_ event: CampaignStartedEvent) {
        ReachuLogger.success("Campaign started: \(event.campaignId)", component: "CampaignManager")
        
        isCampaignActive = true
        campaignState = .active
        
        // Update campaign with new dates
        currentCampaign = Campaign(
            id: event.campaignId,
            startDate: event.startDate,
            endDate: event.endDate,
            isPaused: false
        )
        
        // Save to cache
        if let campaign = currentCampaign {
            CacheManager.shared.saveCampaign(campaign)
        }
        CacheManager.shared.saveCampaignState(campaignState, isActive: isCampaignActive)
        
        // Fetch active components now that campaign is active
        Task {
            await fetchActiveComponents(campaignId: event.campaignId)
        }
        
        // Notify observers
        NotificationCenter.default.post(
            name: .campaignStarted,
            object: nil,
            userInfo: ["campaignId": event.campaignId]
        )
    }
    
    private func handleCampaignEnded(_ event: CampaignEndedEvent) {
        ReachuLogger.warning("Campaign ended: \(event.campaignId)", component: "CampaignManager")
        
        isCampaignActive = false
        campaignState = .ended
        
        // Immediately hide ALL components
        activeComponents.removeAll()
        
        // Update campaign with end date
        if let campaign = currentCampaign {
            currentCampaign = Campaign(
                id: campaign.id,
                startDate: campaign.startDate,
                endDate: event.endDate,
                isPaused: campaign.isPaused
            )
        } else {
            // If campaign wasn't loaded yet, create it with end date
            currentCampaign = Campaign(
                id: event.campaignId,
                startDate: nil,
                endDate: event.endDate,
                isPaused: nil
            )
        }
        
        // Save to cache
        if let campaign = currentCampaign {
            CacheManager.shared.saveCampaign(campaign)
        }
        CacheManager.shared.saveCampaignState(campaignState, isActive: isCampaignActive)
        CacheManager.shared.saveComponents([])
        
        // Notify observers
        NotificationCenter.default.post(
            name: .campaignEnded,
            object: nil,
            userInfo: ["campaignId": event.campaignId]
        )
    }
    
    private func handleCampaignPaused(_ event: CampaignPausedEvent) {
        ReachuLogger.info("Campaign paused: \(event.campaignId)", component: "CampaignManager")
        
        isCampaignActive = false
        
        // Immediately hide ALL components
        activeComponents.removeAll()
        
        // Update campaign with paused state
        if let campaign = currentCampaign {
            currentCampaign = Campaign(
                id: campaign.id,
                startDate: campaign.startDate,
                endDate: campaign.endDate,
                isPaused: true
            )
        } else {
            // If campaign wasn't loaded yet, create it with paused state
            currentCampaign = Campaign(
                id: event.campaignId,
                startDate: nil,
                endDate: nil,
                isPaused: true
            )
        }
        
        // Save to cache
        if let campaign = currentCampaign {
            CacheManager.shared.saveCampaign(campaign)
        }
        CacheManager.shared.saveCampaignState(campaignState, isActive: isCampaignActive)
        CacheManager.shared.saveComponents([])
        
        // Notify observers
        NotificationCenter.default.post(
            name: .campaignPaused,
            object: nil,
            userInfo: ["campaignId": event.campaignId]
        )
    }
    
    private func handleCampaignResumed(_ event: CampaignResumedEvent) {
        ReachuLogger.success("Campaign resumed: \(event.campaignId)", component: "CampaignManager")
        
        isCampaignActive = true
        
        // Update campaign with resumed state
        if let campaign = currentCampaign {
            currentCampaign = Campaign(
                id: campaign.id,
                startDate: campaign.startDate,
                endDate: campaign.endDate,
                isPaused: false
            )
        }
        
        // Save to cache
        if let campaign = currentCampaign {
            CacheManager.shared.saveCampaign(campaign)
        }
        CacheManager.shared.saveCampaignState(campaignState, isActive: isCampaignActive)
        
        // Fetch active components now that campaign is resumed
        Task {
            await fetchActiveComponents(campaignId: event.campaignId)
        }
        
        // Notify observers
        NotificationCenter.default.post(
            name: .campaignResumed,
            object: nil,
            userInfo: ["campaignId": event.campaignId]
        )
    }
    
    private func handleComponentStatusChanged(_ event: ComponentStatusChangedEvent) {
        // Determine status and component ID based on format
        let status: String
        let componentId: String
        
        if let data = event.data {
            // New format
            status = data.status
            componentId = String(data.campaignComponentId)
            ReachuLogger.debug("Component status changed (new format): \(data.componentId) -> \(status)", component: "CampaignManager")
        } else if let legacyStatus = event.status, let legacyComponent = event.component {
            // Legacy format
            status = legacyStatus
            componentId = legacyComponent.id
            ReachuLogger.debug("Component status changed (legacy format): \(legacyComponent.id) -> \(status)", component: "CampaignManager")
        } else {
            ReachuLogger.error("Invalid component_status_changed event - missing required fields", component: "CampaignManager")
            return
        }
        
        // Business rule: Components CANNOT be activated in Upcoming state
        // Even if backend sends activation event, ignore it if campaign hasn't started
        if status == "active" && campaignState == .upcoming {
            ReachuLogger.warning("Ignoring component activation - campaign is upcoming", component: "CampaignManager")
            return
        }
        
        // Business rule: Components CANNOT be activated in Ended state
        if status == "active" && campaignState == .ended {
            ReachuLogger.warning("Ignoring component activation - campaign has ended", component: "CampaignManager")
            return
        }
        
        // Business rule: Components CANNOT be activated if campaign is paused
        if status == "active" && (currentCampaign?.isPaused == true || !isCampaignActive) {
            ReachuLogger.warning("Ignoring component activation - campaign is paused", component: "CampaignManager")
            return
        }
        
        do {
            let component = try event.toComponent()
            
            if status == "active" {
                // Only one component of each type can be active at a time
                // Remove any existing component of the same type first
                activeComponents.removeAll { $0.type == component.type && $0.id != componentId }
                
                // Add or update component
                if let index = activeComponents.firstIndex(where: { $0.id == componentId }) {
                    activeComponents[index] = component
                } else {
                    activeComponents.append(component)
                }
                
                // Save to cache
                CacheManager.shared.saveComponents(activeComponents)
            } else {
                // Remove component
                activeComponents.removeAll { $0.id == componentId }
                
                // Save to cache
                CacheManager.shared.saveComponents(activeComponents)
            }
        } catch {
            ReachuLogger.error("Failed to convert component event: \(error)", component: "CampaignManager")
        }
    }
    
    private func handleComponentConfigUpdated(_ event: ComponentConfigUpdatedEvent) {
        // Log which format we received
        if let componentId = event.componentId {
            ReachuLogger.debug("Component config updated (new format): \(componentId)", component: "CampaignManager")
        } else if let data = event.data {
            ReachuLogger.debug("Component config updated (old format): \(data.componentId)", component: "CampaignManager")
        }
        
        do {
            let component = try event.toComponent()
            let componentId = component.id
            
            // Update existing component's config (match by componentId string)
            if let index = activeComponents.firstIndex(where: { $0.id == componentId }) {
                activeComponents[index] = component
                ReachuLogger.success("Updated component config: \(componentId)", component: "CampaignManager")
                
                // Save to cache
                CacheManager.shared.saveComponents(activeComponents)
            } else {
                // If component doesn't exist yet, add it (only if campaign is active)
                if isCampaignActive && currentCampaign?.isPaused != true {
                    activeComponents.append(component)
                    ReachuLogger.success("Added new component from config update: \(componentId)", component: "CampaignManager")
                    
                    // Save to cache
                    CacheManager.shared.saveComponents(activeComponents)
                } else {
                    ReachuLogger.warning("Cannot add component - campaign not active or paused", component: "CampaignManager")
                }
            }
        } catch {
            ReachuLogger.error("Failed to convert component event: \(error)", component: "CampaignManager")
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    public static let campaignStarted = Notification.Name("ReachuCampaignStarted")
    public static let campaignEnded = Notification.Name("ReachuCampaignEnded")
    public static let campaignPaused = Notification.Name("ReachuCampaignPaused")
    public static let campaignResumed = Notification.Name("ReachuCampaignResumed")
    public static let componentStatusChanged = Notification.Name("ReachuComponentStatusChanged")
    public static let componentConfigUpdated = Notification.Name("ReachuComponentConfigUpdated")
}

