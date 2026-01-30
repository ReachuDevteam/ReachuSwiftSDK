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
    @Published public private(set) var currentMatchContext: MatchContext?  // Current match context for filtering
    @Published public private(set) var activeCampaigns: [Campaign] = []  // Multiple campaigns support
    
    // MARK: - Private Properties
    private var campaignId: Int?  // Legacy: single campaign ID (for backward compatibility)
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
        
        // Check if auto-discovery is enabled
        let autoDiscover = config.campaignConfiguration.autoDiscover
        let configuredCampaignId = config.liveShowConfiguration.campaignId
        
        print("🎯 [CampaignManager] init - autoDiscover: \(autoDiscover), campaignId: \(configuredCampaignId)")
        
        // Backward compatibility logic:
        // - If autoDiscover is true, use auto-discovery (campaignId can be 0)
        // - If autoDiscover is false and campaignId > 0, use legacy single campaign mode
        // - If both are false/0, campaigns are disabled
        if autoDiscover {
            // Auto-discovery mode - campaigns will be discovered when setMatchContext is called
            print("🎯 [CampaignManager] init - Auto-discovery enabled, waiting for setMatchContext")
            self.isCampaignActive = true
            self.campaignState = .active
        } else if configuredCampaignId > 0 {
            // Legacy mode - single campaign
            self.campaignId = configuredCampaignId
            print("🎯 [CampaignManager] init - Legacy mode: Setting campaignId to: \(configuredCampaignId)")
            Task {
                await initializeCampaign()
            }
        } else {
            // No campaign configured - SDK works normally without restrictions
            self.isCampaignActive = true
            self.campaignState = .active
            print("🎯 [CampaignManager] init - No campaignId configured, campaigns disabled")
        }
    }
    
    // MARK: - Public Methods
    
    /// Reinitialize campaign manager with current configuration
    /// Called automatically when ReachuConfiguration is updated
    public func reinitialize() {
        print("🎯 [CampaignManager] reinitialize - Starting reinitialization")
        // Disconnect existing connection
        disconnect()
        
        // Get current configuration
        let config = ReachuConfiguration.shared
        let configuredCampaignId = config.liveShowConfiguration.campaignId
        print("🎯 [CampaignManager] reinitialize - Reading campaignId from config: \(configuredCampaignId)")
        print("🎯 [CampaignManager] reinitialize - Previous campaignId was: \(self.campaignId ?? -1)")
        
        // Update base URL
        self.baseURL = config.environment.graphQLURL
            .replacingOccurrences(of: "/graphql", with: "")
            .replacingOccurrences(of: "/v1/graphql", with: "")
        
        // If campaignId is 0 or not configured, campaigns are disabled (normal SDK behavior)
        if configuredCampaignId > 0 {
            self.campaignId = configuredCampaignId
            print("🎯 [CampaignManager] reinitialize - Setting campaignId to: \(configuredCampaignId)")
            Task {
                await initializeCampaign()
            }
        } else {
            // No campaign configured - SDK works normally without restrictions
            self.campaignId = nil
            self.isCampaignActive = true
            self.campaignState = .active
            self.activeComponents.removeAll()
            print("🎯 [CampaignManager] reinitialize - No campaignId configured, campaigns disabled")
        }
    }
    
    /// Initialize campaign connection (called automatically if campaignId > 0)
    public func initializeCampaign() async {
        guard let campaignId = campaignId, campaignId > 0 else {
            print("🎯 [CampaignManager] initializeCampaign - No campaignId, skipping")
            return
        }
        
        // Prevent multiple simultaneous initializations
        guard !isInitializing else {
            // Campaign initialization already in progress, skip
            print("🎯 [CampaignManager] initializeCampaign - Already initializing, skipping")
            return
        }
        
        isInitializing = true
        defer { 
            isInitializing = false
            print("🎯 [CampaignManager] initializeCampaign - Completed, isInitializing set to false")
        }
        
        print("🎯 [CampaignManager] initializeCampaign - Starting initialization for campaignId: \(campaignId)")
        
        // 0. Load from cache first for instant UI update
        loadFromCache()
        
        // 1. Fetch campaign info and determine initial state
        print("🎯 [CampaignManager] initializeCampaign - Calling fetchCampaignInfo...")
        await fetchCampaignInfo(campaignId: campaignId)
        print("🎯 [CampaignManager] initializeCampaign - fetchCampaignInfo completed")
        
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
    
    /// Set the current match context for filtering campaigns and components
    /// This filters automatically to show only components for the specified match
    public func setMatchContext(_ context: MatchContext) async {
        print("🎯 [CampaignManager] setMatchContext - Setting context: \(context.matchId)")
        
        // Clear components from previous context
        self.activeComponents.removeAll()
        
        // Set new context
        self.currentMatchContext = context
        
        // Reload campaigns and components for this context
        await refreshCampaignsForContext(context)
    }
    
    /// Refresh campaigns and components for a specific match context
    private func refreshCampaignsForContext(_ context: MatchContext) async {
        let config = ReachuConfiguration.shared
        
        // Check if auto-discovery is enabled
        if config.campaignConfiguration.autoDiscover {
            // Use auto-discovery
            await discoverCampaigns(matchId: context.matchId)
        } else if let campaignId = campaignId, campaignId > 0 {
            // Use legacy single campaign mode
            await initializeCampaign()
        }
        
        // Filter components by context
        filterComponentsByContext(context)
    }
    
    /// Filter active components by match context
    /// Components without matchContext are shown for all matches (backward compatibility)
    private func filterComponentsByContext(_ context: MatchContext) {
        let allComponents = self.activeComponents
        self.activeComponents = allComponents.filter { component in
            // Include components without matchContext (backward compatibility)
            guard let componentMatchId = component.matchContext?.matchId else {
                return true  // Show components without matchContext for all matches
            }
            // Include components that match the current matchId
            return componentMatchId == context.matchId
        }
        print("🎯 [CampaignManager] filterComponentsByContext - Filtered to \(self.activeComponents.count) components for matchId: \(context.matchId)")
    }
    
    /// Get components for a specific match context
    /// Components without matchContext are included for backward compatibility
    public func getComponents(for context: MatchContext) -> [Component] {
        return activeComponents.filter { component in
            // Include components without matchContext (backward compatibility)
            guard let componentMatchId = component.matchContext?.matchId else {
                return true  // Show components without matchContext for all matches
            }
            return componentMatchId == context.matchId
        }
    }
    
    /// Check if a component should be displayed based on campaign state and context
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
        
        // If we have a currentMatchContext, verify component belongs to it
        if let context = currentMatchContext {
            guard let componentMatchId = component?.matchContext?.matchId else {
                // Component without matchContext should not be shown when context is active
                return false
            }
            guard componentMatchId == context.matchId else {
                // Component belongs to different match
                return false
            }
        }
        
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
        let config = ReachuConfiguration.shared
        let currentCampaignId = config.liveShowConfiguration.campaignId
        let currentApiKey = config.campaignConfiguration.campaignAdminApiKey.isEmpty 
            ? (config.apiKey.isEmpty ? "DEMO_KEY" : config.apiKey)
            : config.campaignConfiguration.campaignAdminApiKey
        let currentBaseURL = self.baseURL
        
        // Validate cache configuration BEFORE loading anything
        let validation = CacheManager.shared.validateCacheConfiguration(
            currentCampaignId: currentCampaignId,
            currentCampaignAdminApiKey: currentApiKey,
            currentBaseURL: currentBaseURL
        )
        
        if validation.shouldClearCache {
            // Configuration changed or version mismatch - clear cache and hide components
            print("🎯 [CampaignManager] loadFromCache - Configuration changed, clearing cache and hiding components")
            CacheManager.shared.clearCache()
            self.currentCampaign = nil
            self.campaignState = .active
            self.isCampaignActive = false  // Hide all SDK components
            self.activeComponents.removeAll()
            return
        }
        
        // Configuration matches - safe to load from cache
        // But wrap in do-catch for error recovery
        do {
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
            
            // Load components ONLY if campaign is active
            // Also filter by currentMatchContext if set
            if isCampaignActive {
                let cachedComponents = CacheManager.shared.loadComponents()
                
                // Filter by matchContext if currentMatchContext is set
                if let context = currentMatchContext {
                    let filteredComponents = cachedComponents.filter { component in
                        guard let componentMatchId = component.matchContext?.matchId else {
                            // If component has no matchContext, don't show it when context is active (security)
                            return false
                        }
                        return componentMatchId == context.matchId
                    }
                    self.activeComponents = filteredComponents
                } else {
                    // No context set - show all components (legacy mode)
                    self.activeComponents = cachedComponents
                }
            } else {
                // Campaign not active - ensure components are cleared
                self.activeComponents.removeAll()
            }
        } catch {
            // Cache is corrupt - clear it and start fresh
            ReachuLogger.error("Failed to load from cache: \(error) - clearing cache", component: "CampaignManager")
            CacheManager.shared.clearCache()
            self.currentCampaign = nil
            self.campaignState = .active
            self.isCampaignActive = false
            self.activeComponents.removeAll()
        }
    }
    
    /// Fetch campaign information from API using new v1 endpoint
    /// Always uses campaignId from configuration file (reachu-config.json)
    private func fetchCampaignInfo(campaignId: Int) async {
        let config = ReachuConfiguration.shared
        
        // Use campaign admin API key (different from SDK API key)
        let campaignAdminApiKey = config.campaignConfiguration.campaignAdminApiKey.isEmpty 
            ? (config.apiKey.isEmpty ? "DEMO_KEY" : config.apiKey)  // Fallback to SDK API key if not configured
            : config.campaignConfiguration.campaignAdminApiKey
        
        // Always use campaignId from configuration file (reachu-config.json)
        let configuredCampaignId = config.liveShowConfiguration.campaignId
        print("🎯 [CampaignManager] fetchCampaignInfo - Using campaignId from config: \(configuredCampaignId)")
        print("🎯 [CampaignManager] fetchCampaignInfo - campaignAdminApiKey: \(campaignAdminApiKey.prefix(20))...")
        guard configuredCampaignId > 0 else {
            ReachuLogger.warning("No campaignId configured in liveShow.campaignId - skipping campaign info fetch", component: "CampaignManager")
            return
        }
        
        let urlString = "\(campaignRestAPIBaseURL)/v1/sdk/config?apiKey=\(campaignAdminApiKey)&campaignId=\(configuredCampaignId)"
        print("🎯 [CampaignManager] fetchCampaignInfo - Request URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            ReachuLogger.error("Invalid campaign API URL: \(urlString)", component: "CampaignManager")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0  // 10 second timeout
        
        var responseData: Data?
        
        do {
            print("🎯 [CampaignManager] fetchCampaignInfo - Starting URLSession request...")
            print("🎯 [CampaignManager] fetchCampaignInfo - URL: \(url.absoluteString)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            responseData = data
            print("🎯 [CampaignManager] fetchCampaignInfo - Request completed, data size: \(data.count) bytes")
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🎯 [CampaignManager] fetchCampaignInfo - HTTP Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 404 {
                    print("🎯 [CampaignManager] ❌ Campaign \(campaignId) not found (404)")
                    ReachuLogger.warning("Campaign \(campaignId) not found - SDK works normally", component: "CampaignManager")
                    // Campaign not found - allow normal SDK behavior
                    self.isCampaignActive = true
                    self.campaignState = .active
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
                    print("🎯 [CampaignManager] ❌ HTTP Error \(httpResponse.statusCode): \(responseString)")
                    ReachuLogger.error("Campaign info request failed with status \(httpResponse.statusCode): \(responseString)", component: "CampaignManager")
                    // On error, allow normal SDK behavior
                    self.isCampaignActive = true
                    self.campaignState = .active
                    return
                }
            } else {
                print("🎯 [CampaignManager] ⚠️ Response is not HTTPURLResponse")
            }
            
            // Validate that we received JSON, not HTML
            if let responseString = String(data: data, encoding: .utf8), responseString.trimmingCharacters(in: .whitespaces).hasPrefix("<") {
                print("🎯 [CampaignManager] ❌ Received HTML instead of JSON")
                ReachuLogger.error("Received HTML instead of JSON from campaign endpoint", component: "CampaignManager")
                // On error, allow normal SDK behavior
                self.isCampaignActive = true
                self.campaignState = .active
                return
            }
            
            // Log raw JSON response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("🎯 [CampaignManager] Raw SDK Config JSON response: \(responseString)")
            }
            
            // Decode new SDK config response
            let sdkConfig = try JSONDecoder().decode(SDKConfigResponse.self, from: data)
            print("🎯 [CampaignManager] SDK Config decoded - Campaign ID: \(sdkConfig.campaignId)")
            print("🎯 [CampaignManager] SDK Config - campaignLogo from response: \(sdkConfig.campaignLogo ?? "nil")")
            print("🎯 [CampaignManager] SDK Config - campaignLogo isEmpty: \(sdkConfig.campaignLogo?.isEmpty ?? true)")
            
            // Create Campaign model from SDK config response
            // Note: The new endpoint doesn't return startDate/endDate/isPaused, so we preserve existing values
            let existingCampaign = self.currentCampaign
            print("🎯 [CampaignManager] Existing campaign before update: ID=\(existingCampaign?.id ?? -1), logo=\(existingCampaign?.campaignLogo ?? "nil")")
            
            let campaign = Campaign(
                id: sdkConfig.campaignId,
                startDate: existingCampaign?.startDate,
                endDate: existingCampaign?.endDate,
                isPaused: existingCampaign?.isPaused,
                campaignLogo: sdkConfig.campaignLogo,
                matchContext: sdkConfig.matchContext ?? existingCampaign?.matchContext
            )
            
            print("🎯 [CampaignManager] New Campaign created - ID: \(campaign.id), campaignLogo: \(campaign.campaignLogo ?? "nil")")
            
            // Detect changes in campaign configuration
            let oldLogoUrl = existingCampaign?.campaignLogo
            let newLogoUrl = campaign.campaignLogo
            
            // Check if campaign configuration changed
            let campaignChanged = existingCampaign != campaign
            
            self.currentCampaign = campaign
            print("🎯 [CampaignManager] currentCampaign updated - ID: \(self.currentCampaign?.id ?? -1), campaignLogo: \(self.currentCampaign?.campaignLogo ?? "nil")")
            
            self.campaignState = campaign.currentState
            
            // If campaign configuration changed, invalidate cache appropriately
            if campaignChanged {
                // Check if logo specifically changed
                let logoChanged = oldLogoUrl != newLogoUrl
                
                if logoChanged, let oldLogo = oldLogoUrl {
                    // Logo changed - invalidate old logo
                    print("🎯 [CampaignManager] Logo changed - invalidating old logo: \(oldLogo)")
                    NotificationCenter.default.post(
                        name: .campaignLogoChanged,
                        object: nil,
                        userInfo: [
                            "oldLogoUrl": oldLogo,
                            "newLogoUrl": newLogoUrl ?? ""
                        ]
                    )
                } else if !logoChanged, let currentLogo = newLogoUrl {
                    // Other configuration changed (dates, state, matchContext) but logo is same
                    // Invalidate current logo to ensure branding changes are reflected
                    print("🎯 [CampaignManager] Campaign configuration changed (logo unchanged) - invalidating current logo: \(currentLogo)")
                    NotificationCenter.default.post(
                        name: .campaignLogoChanged,
                        object: nil,
                        userInfo: [
                            "oldLogoUrl": currentLogo,
                            "newLogoUrl": newLogoUrl ?? ""
                        ]
                    )
                }
                
                // Pre-load new logo if it changed (will be cached by ImageLoader)
                if let logoUrl = newLogoUrl, logoUrl != oldLogoUrl, let url = URL(string: logoUrl) {
                    // Pre-load logo in background to cache it
                    Task {
                        _ = try? await URLSession.shared.data(from: url)
                    }
                }
            }
            
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
            
            // Save configuration hash for future validation
            let config = ReachuConfiguration.shared
            let apiKey = config.campaignConfiguration.campaignAdminApiKey.isEmpty 
                ? (config.apiKey.isEmpty ? "DEMO_KEY" : config.apiKey)
                : config.campaignConfiguration.campaignAdminApiKey
            CacheManager.shared.saveCacheConfiguration(
                campaignId: campaign.id,
                campaignAdminApiKey: apiKey,
                baseURL: self.baseURL
            )
            
        } catch let decodingError as DecodingError {
            print("🎯 [CampaignManager] ❌ Decoding Error: \(decodingError)")
            if case .dataCorrupted(let context) = decodingError {
                print("🎯 [CampaignManager] Data corrupted at: \(context.debugDescription)")
                if let data = responseData, let dataString = String(data: data, encoding: .utf8) {
                    print("🎯 [CampaignManager] Raw data: \(dataString)")
                }
            }
            ReachuLogger.error("Failed to decode campaign info: \(decodingError)", component: "CampaignManager")
            // On error, allow normal SDK behavior
            self.isCampaignActive = true
            self.campaignState = .active
        } catch {
            print("🎯 [CampaignManager] ❌ Network/Other Error: \(error.localizedDescription)")
            print("🎯 [CampaignManager] ❌ Error details: \(error)")
            ReachuLogger.warning("Failed to fetch campaign info: \(error)", component: "CampaignManager")
            // On error, allow normal SDK behavior
            self.isCampaignActive = true
            self.campaignState = .active
        }
    }
    
    /// Discover campaigns using auto-discovery endpoint
    /// Uses only the Reachu SDK API key (no campaignAdminApiKey needed)
    /// - Parameter matchId: Optional matchId to filter campaigns for a specific match
    public func discoverCampaigns(matchId: String? = nil) async {
        let config = ReachuConfiguration.shared
        let apiKey = config.apiKey
        
        guard !apiKey.isEmpty else {
            ReachuLogger.error("Cannot discover campaigns: API key is empty", component: "CampaignManager")
            return
        }
        
        var urlString = "\(campaignRestAPIBaseURL)/v1/sdk/campaigns?apiKey=\(apiKey)"
        if let matchId = matchId {
            urlString += "&matchId=\(matchId)"
        }
        
        guard let url = URL(string: urlString) else {
            ReachuLogger.error("Invalid campaigns discovery URL: \(urlString)", component: "CampaignManager")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0
        
        do {
            print("🎯 [CampaignManager] discoverCampaigns - Starting discovery request...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
                    ReachuLogger.error("Campaigns discovery failed with status \(httpResponse.statusCode): \(responseString)", component: "CampaignManager")
                    return
                }
            }
            
            // Decode campaigns discovery response
            let discoveryResponse = try JSONDecoder().decode(CampaignsDiscoveryResponse.self, from: data)
            
            // Convert discovery items to Campaign models
            var discoveredCampaigns: [Campaign] = []
            var allComponents: [Component] = []
            
            for item in discoveryResponse.campaigns {
                let campaign = Campaign(
                    id: item.campaignId,
                    startDate: item.startDate,
                    endDate: item.endDate,
                    isPaused: item.isPaused,
                    campaignLogo: item.campaignLogo,
                    matchContext: item.matchContext
                )
                discoveredCampaigns.append(campaign)
                
                // Process components from discovery response
                if let componentItems = item.components {
                    for componentItem in componentItems {
                        // Convert ComponentDiscoveryItem to Component
                        // Note: This requires decoding ComponentConfig from the config dictionary
                        do {
                            let configData = try JSONSerialization.data(withJSONObject: componentItem.config.mapValues { $0.value })
                            let componentConfig = try JSONDecoder().decode(ComponentConfig.self, from: configData)
                            
                            let component = Component(
                                id: componentItem.id,
                                type: componentItem.type,
                                name: componentItem.name,
                                config: componentConfig,
                                status: componentItem.status,
                                matchContext: componentItem.matchContext
                            )
                            allComponents.append(component)
                        } catch {
                            ReachuLogger.error("Failed to decode component from discovery: \(error)", component: "CampaignManager")
                        }
                    }
                }
            }
            
            // Update active campaigns
            self.activeCampaigns = discoveredCampaigns
            
            // Filter components by currentMatchContext if set
            // Components without matchContext are shown for all matches (backward compatibility)
            if let context = currentMatchContext {
                self.activeComponents = allComponents.filter { component in
                    // Include components without matchContext (backward compatibility)
                    guard let componentMatchId = component.matchContext?.matchId else {
                        return true  // Show components without matchContext for all matches
                    }
                    // Include components that match the current matchId
                    return componentMatchId == context.matchId
                }
            } else {
                self.activeComponents = allComponents
            }
            
            // Set current campaign to first active campaign if available
            if let firstActiveCampaign = discoveredCampaigns.first(where: { $0.currentState == .active && $0.isPaused != true }) {
                // Detect changes in campaign configuration
                let existingCampaign = self.currentCampaign
                let oldLogoUrl = existingCampaign?.campaignLogo
                let newLogoUrl = firstActiveCampaign.campaignLogo
                
                // Check if campaign configuration changed
                let campaignChanged = existingCampaign != firstActiveCampaign
                
                self.currentCampaign = firstActiveCampaign
                self.campaignState = firstActiveCampaign.currentState
                self.isCampaignActive = true
                
                // If campaign configuration changed, invalidate cache appropriately
                if campaignChanged {
                    // Check if logo specifically changed
                    let logoChanged = oldLogoUrl != newLogoUrl
                    
                    if logoChanged, let oldLogo = oldLogoUrl {
                        // Logo changed - invalidate old logo
                        print("🎯 [CampaignManager] Logo changed in discovery - invalidating old logo: \(oldLogo)")
                        NotificationCenter.default.post(
                            name: .campaignLogoChanged,
                            object: nil,
                            userInfo: [
                                "oldLogoUrl": oldLogo,
                                "newLogoUrl": newLogoUrl ?? ""
                            ]
                        )
                    } else if !logoChanged, let currentLogo = newLogoUrl {
                        // Other configuration changed (dates, state, matchContext) but logo is same
                        // Invalidate current logo to ensure branding changes are reflected
                        print("🎯 [CampaignManager] Campaign configuration changed in discovery (logo unchanged) - invalidating current logo: \(currentLogo)")
                        NotificationCenter.default.post(
                            name: .campaignLogoChanged,
                            object: nil,
                            userInfo: [
                                "oldLogoUrl": currentLogo,
                                "newLogoUrl": newLogoUrl ?? ""
                            ]
                        )
                    }
                    
                    // Pre-load new logo if it changed (will be cached by ImageLoader)
                    if let logoUrl = newLogoUrl, logoUrl != oldLogoUrl, let url = URL(string: logoUrl) {
                        // Pre-load logo in background to cache it
                        Task {
                            _ = try? await URLSession.shared.data(from: url)
                        }
                    }
                }
            }
            
            // Cache components
            CacheManager.shared.saveComponents(self.activeComponents)
            
            print("🎯 [CampaignManager] discoverCampaigns - Discovered \(discoveredCampaigns.count) campaigns, \(self.activeComponents.count) components")
            
        } catch {
            ReachuLogger.error("Failed to discover campaigns: \(error)", component: "CampaignManager")
        }
    }
    
    /// Fetch active components from API using new v1 endpoint
    /// Always uses campaignId from configuration file (reachu-config.json)
    private func fetchActiveComponents(campaignId: Int) async {
        let config = ReachuConfiguration.shared
        
        // Use campaign admin API key (different from SDK API key)
        let campaignAdminApiKey = config.campaignConfiguration.campaignAdminApiKey.isEmpty 
            ? (config.apiKey.isEmpty ? "DEMO_KEY" : config.apiKey)  // Fallback to SDK API key if not configured
            : config.campaignConfiguration.campaignAdminApiKey
        
        let countryCode = config.marketConfiguration.countryCode
        
        // Always use campaignId from configuration file (reachu-config.json)
        let configuredCampaignId = config.liveShowConfiguration.campaignId
        guard configuredCampaignId > 0 else {
            ReachuLogger.warning("No campaignId configured in liveShow.campaignId - skipping components fetch", component: "CampaignManager")
            return
        }
        
        // Build URL with query parameters
        var urlComponents = URLComponents(string: "\(campaignRestAPIBaseURL)/v1/offers")
        urlComponents?.queryItems = [
            URLQueryItem(name: "apiKey", value: campaignAdminApiKey),
            URLQueryItem(name: "campaignId", value: "\(configuredCampaignId)")
        ]
        
        // Add optional userCountry if available
        if !countryCode.isEmpty {
            urlComponents?.queryItems?.append(URLQueryItem(name: "userCountry", value: countryCode))
        }
        
        guard let url = urlComponents?.url else {
            ReachuLogger.error("Invalid offers API URL", component: "CampaignManager")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Validate HTTP response before decoding
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
                    ReachuLogger.error("Offers request failed with status \(httpResponse.statusCode): \(responseString)", component: "CampaignManager")
                    
                    // If 404, campaign might not have offers configured - this is OK
                    if httpResponse.statusCode == 404 {
                        self.activeComponents = []
                        return
                    }
                    return
                }
            }
            
            // Validate that we received JSON, not HTML
            if let responseString = String(data: data, encoding: .utf8), responseString.trimmingCharacters(in: .whitespaces).hasPrefix("<") {
                ReachuLogger.error("Received HTML instead of JSON from offers endpoint", component: "CampaignManager")
                return
            }
            
            // Decode new offers response
            let offersResponse = try JSONDecoder().decode(OffersResponse.self, from: data)
            
            // Update campaign logo if available from offers response
            if let logo = offersResponse.campaignLogo, !logo.isEmpty {
                let existingCampaign = self.currentCampaign
                
                self.currentCampaign = Campaign(
                    id: existingCampaign?.id ?? offersResponse.campaignId,
                    startDate: existingCampaign?.startDate,
                    endDate: existingCampaign?.endDate,
                    isPaused: existingCampaign?.isPaused,
                    campaignLogo: logo
                )
            }
            
            // Convert offers to components
            let components = try offersResponse.offers.map { offer -> Component in
                // Convert OfferResponse config to ComponentConfig
                let jsonData = try JSONSerialization.data(withJSONObject: offer.config.mapValues { $0.value })
                let componentConfig = try JSONDecoder().decode(ComponentConfig.self, from: jsonData)
                
                return Component(
                    id: offer.id,
                    type: offer.type,
                    name: offer.name,
                    config: componentConfig,
                    status: "active" // All offers from /v1/offers are active
                )
            }
            
            // All offers are active by default
            // Filter components by currentMatchContext if set
            if let context = currentMatchContext {
                self.activeComponents = components.filter { component in
                    guard let componentMatchId = component.matchContext?.matchId else {
                        // Component without matchContext should not be shown when context is active (security)
                        return false
                    }
                    return componentMatchId == context.matchId
                }
            } else {
                // No context set - show all components (legacy mode)
                self.activeComponents = components
            }
            
            // Components loaded
            if !self.activeComponents.isEmpty {
                ReachuLogger.debug("Active component types: \(self.activeComponents.map { $0.type }.joined(separator: ", "))", component: "CampaignManager")
            }
            
            // Save to cache
            CacheManager.shared.saveComponents(self.activeComponents)
            
        } catch let decodingError as DecodingError {
            ReachuLogger.error("Failed to decode offers: \(decodingError)", component: "CampaignManager")
            
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
        } catch {
            ReachuLogger.warning("Failed to fetch active components: \(error)", component: "CampaignManager")
        }
    }
    
    /// Connect to campaign WebSocket
    /// Always uses campaignId from configuration file (reachu-config.json)
    /// According to backend behavior:
    /// - If campaign is Ended: Backend sends campaign_ended immediately
    /// - If campaign is Upcoming: No event sent, waits for campaign_started
    /// - If campaign is Active: No event sent, can fetch components
    private func connectWebSocket(campaignId: Int) async {
        // Always use campaignId from configuration file (reachu-config.json)
        let config = ReachuConfiguration.shared
        let configuredCampaignId = config.liveShowConfiguration.campaignId
        guard configuredCampaignId > 0 else {
            ReachuLogger.warning("No campaignId configured in liveShow.campaignId - skipping WebSocket connection", component: "CampaignManager")
            return
        }
        
        print("🎯 [CampaignManager] connectWebSocket - Using campaignId from config file: \(configuredCampaignId)")
        
        // Use the campaign WebSocket endpoint, not the GraphQL endpoint
        webSocketManager = CampaignWebSocketManager(campaignId: configuredCampaignId, baseURL: campaignWebSocketBaseURL)
        
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
        
        // Update campaign with new dates, preserve existing campaignLogo if available
        let existingCampaign = currentCampaign
        let existingLogo = existingCampaign?.campaignLogo
        
        let newCampaign = Campaign(
            id: event.campaignId,
            startDate: event.startDate,
            endDate: event.endDate,
            isPaused: false,
            campaignLogo: existingLogo
        )
        
        // Detect if campaign configuration changed
        let campaignChanged = existingCampaign != newCampaign
        let oldLogoUrl = existingCampaign?.campaignLogo
        let newLogoUrl = newCampaign.campaignLogo
        
        currentCampaign = newCampaign
        
        ReachuLogger.debug("Campaign started - ID: \(event.campaignId), preserving campaignLogo: \(existingLogo ?? "nil")", component: "CampaignManager")
        
        // If campaign configuration changed, invalidate cache appropriately
        if campaignChanged {
            // Check if logo specifically changed
            let logoChanged = oldLogoUrl != newLogoUrl
            
            if logoChanged, let oldLogo = oldLogoUrl {
                // Logo changed - invalidate old logo
                ReachuLogger.debug("Logo changed in campaign_started - invalidating old logo: \(oldLogo)", component: "CampaignManager")
                NotificationCenter.default.post(
                    name: .campaignLogoChanged,
                    object: nil,
                    userInfo: [
                        "oldLogoUrl": oldLogo,
                        "newLogoUrl": newLogoUrl ?? ""
                    ]
                )
            } else if !logoChanged, let currentLogo = newLogoUrl {
                // Other configuration changed (dates) but logo is same
                // Invalidate current logo to ensure branding changes are reflected
                ReachuLogger.debug("Campaign configuration changed in campaign_started (logo unchanged) - invalidating current logo: \(currentLogo)", component: "CampaignManager")
                NotificationCenter.default.post(
                    name: .campaignLogoChanged,
                    object: nil,
                    userInfo: [
                        "oldLogoUrl": currentLogo,
                        "newLogoUrl": newLogoUrl ?? ""
                    ]
                )
            }
        }
        
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
        
        // Get logo before updating campaign (to clear it from cache)
        let campaignLogoToClear = currentCampaign?.campaignLogo
        
        // Update campaign with end date, preserve existing campaignLogo if available
        if let campaign = currentCampaign {
            currentCampaign = Campaign(
                id: campaign.id,
                startDate: campaign.startDate,
                endDate: event.endDate,
                isPaused: campaign.isPaused,
                campaignLogo: campaign.campaignLogo
            )
        } else {
            // If campaign wasn't loaded yet, create it with end date
            currentCampaign = Campaign(
                id: event.campaignId,
                startDate: nil,
                endDate: event.endDate,
                isPaused: nil,
                campaignLogo: nil
            )
        }
        
        // Save to cache
        if let campaign = currentCampaign {
            CacheManager.shared.saveCampaign(campaign)
        }
        CacheManager.shared.saveCampaignState(campaignState, isActive: isCampaignActive)
        CacheManager.shared.saveComponents([])
        
        // Clear logo from cache when campaign ends
        if let logoUrl = campaignLogoToClear {
            print("🎯 [CampaignManager] Campaign ended - clearing logo from cache: \(logoUrl)")
            NotificationCenter.default.post(
                name: .campaignLogoChanged,
                object: nil,
                userInfo: [
                    "oldLogoUrl": logoUrl,
                    "newLogoUrl": ""
                ]
            )
        }
        
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
        
        // Update campaign with paused state, preserve existing campaignLogo if available
        if let campaign = currentCampaign {
            currentCampaign = Campaign(
                id: campaign.id,
                startDate: campaign.startDate,
                endDate: campaign.endDate,
                isPaused: true,
                campaignLogo: campaign.campaignLogo
            )
        } else {
            // If campaign wasn't loaded yet, create it with paused state
            currentCampaign = Campaign(
                id: event.campaignId,
                startDate: nil,
                endDate: nil,
                isPaused: true,
                campaignLogo: nil
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
        
        // Update campaign with resumed state, preserve existing campaignLogo if available
        if let campaign = currentCampaign {
            currentCampaign = Campaign(
                id: campaign.id,
                startDate: campaign.startDate,
                endDate: campaign.endDate,
                isPaused: false,
                campaignLogo: campaign.campaignLogo
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
        // Filter by match context if currentMatchContext is set
        if let context = currentMatchContext, let eventMatchId = event.matchId {
            guard eventMatchId == context.matchId else {
                ReachuLogger.debug("Ignoring component status change - event matchId (\(eventMatchId)) != current matchId (\(context.matchId))", component: "CampaignManager")
                return
            }
        }
        
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
                // Filter by match context if currentMatchContext is set
                if let context = currentMatchContext {
                    guard component.matchContext?.matchId == context.matchId else {
                        ReachuLogger.debug("Ignoring component activation - component matchId (\(component.matchContext?.matchId ?? "nil")) != current matchId (\(context.matchId))", component: "CampaignManager")
                        return
                    }
                }
                
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
    public static let campaignLogoChanged = Notification.Name("ReachuCampaignLogoChanged")
}

