import Foundation
import Combine
import ReachuCore

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
            print("📋 [CampaignManager] No campaign configured (campaignId: 0) - SDK works normally")
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
            print("📋 [CampaignManager] No campaign configured (campaignId: 0) - SDK works normally")
        }
    }
    
    /// Initialize campaign connection (called automatically if campaignId > 0)
    public func initializeCampaign() async {
        guard let campaignId = campaignId, campaignId > 0 else {
            print("📋 [CampaignManager] No campaign ID configured - SDK works normally")
            return
        }
        
        print("📋 [CampaignManager] Initializing campaign: \(campaignId)")
        
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
    public func getActiveComponent(type: String) -> Component? {
        guard isCampaignActive else { return nil }
        return activeComponents.first { $0.type == type && $0.isActive }
    }
    
    /// Disconnect from campaign
    public func disconnect() {
        webSocketManager?.disconnect()
        webSocketManager = nil
        isConnected = false
    }
    
    // MARK: - Private Methods
    
    /// Fetch campaign information from API
    private func fetchCampaignInfo(campaignId: Int) async {
        let urlString = "\(campaignRestAPIBaseURL)/\(campaignId)"
        guard let url = URL(string: urlString) else {
            print("❌ [CampaignManager] Invalid campaign API URL: \(urlString)")
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 404 {
                    print("⚠️ [CampaignManager] Campaign \(campaignId) not found - SDK works normally")
                    // Campaign not found - allow normal SDK behavior
                    self.isCampaignActive = true
                    self.campaignState = .active
                    return
                }
            }
            
            let campaign = try JSONDecoder().decode(Campaign.self, from: data)
            self.currentCampaign = campaign
            self.campaignState = campaign.currentState
            
            // Check if campaign is paused first (takes priority over date-based state)
            if campaign.isPaused == true {
                self.isCampaignActive = false
                self.activeComponents.removeAll()
                print("⏸️ [CampaignManager] Campaign \(campaignId) is paused - hiding all components")
                return
            }
            
            // Update active state based on campaign state
            switch campaignState {
            case .upcoming:
                self.isCampaignActive = false
                print("📋 [CampaignManager] Campaign \(campaignId) is upcoming - waiting for start")
            case .active:
                self.isCampaignActive = true
                print("✅ [CampaignManager] Campaign \(campaignId) is active")
            case .ended:
                self.isCampaignActive = false
                self.activeComponents.removeAll()
                print("❌ [CampaignManager] Campaign \(campaignId) has ended - hiding all components")
            }
            
        } catch {
            print("⚠️ [CampaignManager] Failed to fetch campaign info: \(error)")
            // On error, allow normal SDK behavior
            self.isCampaignActive = true
            self.campaignState = .active
        }
    }
    
    /// Fetch active components from API
    private func fetchActiveComponents(campaignId: Int) async {
        let urlString = "\(campaignRestAPIBaseURL)/\(campaignId)/components"
        guard let url = URL(string: urlString) else {
            print("❌ [CampaignManager] Invalid components API URL")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let components = try JSONDecoder().decode([Component].self, from: data)
            
            // Filter to only active components
            self.activeComponents = components.filter { $0.isActive }
            
            print("✅ [CampaignManager] Loaded \(self.activeComponents.count) active components")
            
        } catch {
            print("⚠️ [CampaignManager] Failed to fetch active components: \(error)")
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
        print("✅ [CampaignManager] Campaign started: \(event.campaignId)")
        
        isCampaignActive = true
        campaignState = .active
        
        // Update campaign with new dates
        currentCampaign = Campaign(
            id: event.campaignId,
            startDate: event.startDate,
            endDate: event.endDate,
            isPaused: false
        )
        
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
        print("❌ [CampaignManager] Campaign ended: \(event.campaignId)")
        
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
        
        // Notify observers
        NotificationCenter.default.post(
            name: .campaignEnded,
            object: nil,
            userInfo: ["campaignId": event.campaignId]
        )
    }
    
    private func handleCampaignPaused(_ event: CampaignPausedEvent) {
        print("⏸️ [CampaignManager] Campaign paused: \(event.campaignId)")
        
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
        
        // Notify observers
        NotificationCenter.default.post(
            name: .campaignPaused,
            object: nil,
            userInfo: ["campaignId": event.campaignId]
        )
    }
    
    private func handleCampaignResumed(_ event: CampaignResumedEvent) {
        print("▶️ [CampaignManager] Campaign resumed: \(event.campaignId)")
        
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
        print("📨 [CampaignManager] Component status changed: \(event.componentId) -> \(event.status)")
        
        // Business rule: Components CANNOT be activated in Upcoming state
        // Even if backend sends activation event, ignore it if campaign hasn't started
        if event.status == "active" && campaignState == .upcoming {
            print("⚠️ [CampaignManager] Ignoring component activation - campaign is upcoming")
            return
        }
        
        // Business rule: Components CANNOT be activated in Ended state
        if event.status == "active" && campaignState == .ended {
            print("⚠️ [CampaignManager] Ignoring component activation - campaign has ended")
            return
        }
        
        // Business rule: Components CANNOT be activated if campaign is paused
        if event.status == "active" && (currentCampaign?.isPaused == true || !isCampaignActive) {
            print("⚠️ [CampaignManager] Ignoring component activation - campaign is paused")
            return
        }
        
        if event.status == "active", let component = event.component {
            // Only one component of each type can be active at a time
            // Remove any existing component of the same type first
            activeComponents.removeAll { $0.type == component.type && $0.id != event.componentId }
            
            // Add or update component
            if let index = activeComponents.firstIndex(where: { $0.id == event.componentId }) {
                activeComponents[index] = component
            } else {
                activeComponents.append(component)
            }
        } else {
            // Remove component
            activeComponents.removeAll { $0.id == event.componentId }
        }
    }
    
    private func handleComponentConfigUpdated(_ event: ComponentConfigUpdatedEvent) {
        print("📨 [CampaignManager] Component config updated: \(event.componentId)")
        
        // Update existing component's config
        if let index = activeComponents.firstIndex(where: { $0.id == event.componentId }) {
            activeComponents[index] = event.component
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

