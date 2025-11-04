import Foundation
import ReachuCore

/// WebSocket Manager for Campaign Lifecycle Events
@MainActor
public class CampaignWebSocketManager: ObservableObject {
    
    // MARK: - Properties
    private let campaignId: Int
    private let baseURL: String
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private var reconnectTimer: Timer?
    private var reconnectAttempts: Int = 0
    private let maxReconnectAttempts: Int = 5
    
    // MARK: - Event Callbacks
    public var onCampaignStarted: ((CampaignStartedEvent) -> Void)?
    public var onCampaignEnded: ((CampaignEndedEvent) -> Void)?
    public var onCampaignPaused: ((CampaignPausedEvent) -> Void)?
    public var onCampaignResumed: ((CampaignResumedEvent) -> Void)?
    public var onComponentStatusChanged: ((ComponentStatusChangedEvent) -> Void)?
    public var onComponentConfigUpdated: ((ComponentConfigUpdatedEvent) -> Void)?
    public var onConnectionStatusChanged: ((Bool) -> Void)?
    
    // MARK: - Initialization
    public init(campaignId: Int, baseURL: String) {
        self.campaignId = campaignId
        self.baseURL = baseURL
        self.urlSession = URLSession(configuration: .default)
    }
    
    // MARK: - Connection Management
    
    /// Connect to campaign WebSocket
    public func connect() async {
        // Build WebSocket URL
        let wsURLString = baseURL
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
        let urlString = "\(wsURLString)/ws/\(campaignId)"
        
        guard let url = URL(string: urlString) else {
            print("❌ [CampaignWebSocket] Invalid WebSocket URL: \(urlString)")
            print("   Base URL: \(baseURL)")
            print("   Campaign ID: \(campaignId)")
            return
        }
        
        print("🔌 [CampaignWebSocket] Connecting to: \(urlString)")
        print("   Base URL: \(baseURL)")
        print("   Campaign ID: \(campaignId)")
        
        // Create URLRequest with potential authentication headers
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        
        // Add API key to headers if available
        let config = ReachuConfiguration.shared
        if !config.apiKey.isEmpty {
            request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
            print("   Using API Key: \(config.apiKey.prefix(8))...")
        }
        
        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()
        
        onConnectionStatusChanged?(true)
        
        // Start listening for messages
        await listenForMessages()
    }
    
    /// Disconnect from WebSocket
    public func disconnect() {
        print("🔌 [CampaignWebSocket] Disconnecting from campaign \(campaignId)")
        
        stopReconnectTimer()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        onConnectionStatusChanged?(false)
    }
    
    // MARK: - Message Handling
    
    private func listenForMessages() async {
        while let webSocketTask = webSocketTask {
            do {
                let message = try await webSocketTask.receive()
                
                switch message {
                case .string(let text):
                    await handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        await handleMessage(text)
                    }
                @unknown default:
                    break
                }
                
            } catch {
                print("❌ [CampaignWebSocket] WebSocket error: \(error)")
                
                // Check if it's a connection error that we should retry
                if let urlError = error as? URLError {
                    print("   Error code: \(urlError.code.rawValue)")
                    print("   Error description: \(urlError.localizedDescription)")
                    
                    // Don't retry for certain errors (like authentication failures)
                    if urlError.code == .userAuthenticationRequired || urlError.code == .userCancelledAuthentication {
                        print("⚠️ [CampaignWebSocket] Authentication error - stopping reconnection attempts")
                        onConnectionStatusChanged?(false)
                        return
                    }
                }
                
                // Try to reconnect
                await attemptReconnect()
                break
            }
        }
    }
    
    private func handleMessage(_ text: String) async {
        guard let data = text.data(using: .utf8) else {
            print("❌ [CampaignWebSocket] Invalid message data")
            return
        }
        
        // Parse event type first
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let eventType = json["type"] as? String else {
            print("❌ [CampaignWebSocket] Failed to parse event type")
            return
        }
        
        print("📨 [CampaignWebSocket] Received event: \(eventType)")
        
        // Handle based on event type
        do {
            switch eventType {
            case "campaign_started":
                let event = try JSONDecoder().decode(CampaignStartedEvent.self, from: data)
                onCampaignStarted?(event)
                
            case "campaign_ended":
                let event = try JSONDecoder().decode(CampaignEndedEvent.self, from: data)
                onCampaignEnded?(event)
                
            case "campaign_paused":
                let event = try JSONDecoder().decode(CampaignPausedEvent.self, from: data)
                onCampaignPaused?(event)
                
            case "campaign_resumed":
                let event = try JSONDecoder().decode(CampaignResumedEvent.self, from: data)
                onCampaignResumed?(event)
                
            case "component_status_changed":
                let event = try JSONDecoder().decode(ComponentStatusChangedEvent.self, from: data)
                onComponentStatusChanged?(event)
                
            case "component_config_updated":
                let event = try JSONDecoder().decode(ComponentConfigUpdatedEvent.self, from: data)
                onComponentConfigUpdated?(event)
                
            default:
                print("⚠️ [CampaignWebSocket] Unknown event type: \(eventType)")
            }
        } catch {
            print("❌ [CampaignWebSocket] Failed to decode \(eventType): \(error)")
        }
    }
    
    // MARK: - Reconnection Logic
    
    private func attemptReconnect() async {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("❌ [CampaignWebSocket] Max reconnection attempts reached")
            onConnectionStatusChanged?(false)
            return
        }
        
        reconnectAttempts += 1
        let delay = min(30.0, pow(2.0, Double(reconnectAttempts))) // Exponential backoff, max 30s
        
        print("🔄 [CampaignWebSocket] Reconnecting in \(delay) seconds (attempt \(reconnectAttempts)/\(maxReconnectAttempts))")
        
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        await connect()
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        reconnectAttempts = 0
    }
}

