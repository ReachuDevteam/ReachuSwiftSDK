import Foundation
import Combine

/// WebSocket client for real-time Tipio events
@MainActor
public class TipioWebSocketClient: NSObject, ObservableObject {
    
    // MARK: - Properties
    @Published public private(set) var isConnected = false
    @Published public private(set) var connectionStatus: ConnectionStatus = .disconnected
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession
    private let baseUrl: String
    private let apiKey: String
    private var reconnectTimer: Timer?
    private var heartbeatTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts: Int
    private let heartbeatInterval: TimeInterval
    
    // Event publishers
    private let eventSubject = PassthroughSubject<TipioEvent, Never>()
    private let connectionSubject = PassthroughSubject<ConnectionStatus, Never>()
    
    public var eventPublisher: AnyPublisher<TipioEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    public var connectionPublisher: AnyPublisher<ConnectionStatus, Never> {
        connectionSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Connection Status
    public enum ConnectionStatus: Equatable {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case error(String)
        
        public static func == (lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
            switch (lhs, rhs) {
            case (.disconnected, .disconnected): return true
            case (.connecting, .connecting): return true
            case (.connected, .connected): return true
            case (.reconnecting, .reconnecting): return true
            case (.error(let lhsError), .error(let rhsError)): return lhsError == rhsError
            default: return false
            }
        }
        
        public var displayName: String {
            switch self {
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting"
            case .connected: return "Connected"
            case .reconnecting: return "Reconnecting"
            case .error(let message): return "Error: \(message)"
            }
        }
    }
    
    // MARK: - Initialization
    public init(
        baseUrl: String,
        apiKey: String,
        maxReconnectAttempts: Int = 5,
        heartbeatInterval: TimeInterval = 30
    ) {
        self.baseUrl = baseUrl
        self.apiKey = apiKey
        self.maxReconnectAttempts = maxReconnectAttempts
        self.heartbeatInterval = heartbeatInterval
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        
        super.init()
        
        print("🔌 [TipioWS] WebSocket client initialized")
    }
    
    // MARK: - Connection Management
    
    /// Connect to Tipio WebSocket
    public func connect() {
        guard connectionStatus != .connecting && connectionStatus != .connected else {
            print("🔌 [TipioWS] Already connecting or connected")
            return
        }
        
        updateConnectionStatus(.connecting)
        
        // Build WebSocket URL
        guard let url = buildWebSocketURL() else {
            updateConnectionStatus(.error("Invalid WebSocket URL"))
            return
        }
        
        print("🔌 [TipioWS] Connecting to: \(url.absoluteString)")
        
        // Create WebSocket task
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("ReachuSDK/1.0", forHTTPHeaderField: "User-Agent")
        
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // Start listening for messages
        receiveMessage()
        
        // Start heartbeat after connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.startHeartbeat()
        }
    }
    
    /// Disconnect from WebSocket
    public func disconnect() {
        print("🔌 [TipioWS] Disconnecting...")
        
        stopHeartbeat()
        stopReconnectTimer()
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        updateConnectionStatus(.disconnected)
    }
    
    /// Subscribe to events for a specific livestream
    public func subscribeToStream(_ streamId: Int) {
        guard isConnected else {
            print("❌ [TipioWS] Cannot subscribe - not connected")
            return
        }
        
        let subscribeMessage: [String: Any] = [
            "action": "subscribe",
            "stream_id": streamId,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        sendMessage(subscribeMessage)
        print("📺 [TipioWS] Subscribed to stream: \(streamId)")
    }
    
    /// Unsubscribe from events for a specific livestream
    public func unsubscribeFromStream(_ streamId: Int) {
        guard isConnected else {
            print("❌ [TipioWS] Cannot unsubscribe - not connected")
            return
        }
        
        let unsubscribeMessage: [String: Any] = [
            "action": "unsubscribe",
            "stream_id": streamId,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        sendMessage(unsubscribeMessage)
        print("📺 [TipioWS] Unsubscribed from stream: \(streamId)")
    }
    
    // MARK: - Private Methods
    
    private func buildWebSocketURL() -> URL? {
        // Convert HTTP(S) URL to WebSocket URL
        let wsUrl = baseUrl
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
        
        guard var components = URLComponents(string: wsUrl + "/ws") else {
            return nil
        }
        
        // Add API key as query parameter
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey)
        ]
        
        return components.url
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            DispatchQueue.main.async {
                self?.handleReceivedMessage(result)
            }
        }
    }
    
    private func handleReceivedMessage(_ result: Result<URLSessionWebSocketTask.Message, Error>) {
        switch result {
        case .success(let message):
            switch message {
            case .string(let text):
                handleTextMessage(text)
            case .data(let data):
                handleDataMessage(data)
            @unknown default:
                print("❌ [TipioWS] Unknown message type")
            }
            
            // Continue listening
            receiveMessage()
            
        case .failure(let error):
            print("❌ [TipioWS] Receive error: \(error)")
            handleConnectionError(error)
        }
    }
    
    private func handleTextMessage(_ text: String) {
        print("📨 [TipioWS] Received text: \(text)")
        
        // Handle connection confirmation
        if text.contains("connected") || text.contains("welcome") {
            updateConnectionStatus(.connected)
            resetReconnectAttempts()
            return
        }
        
        // Handle ping/pong
        if text == "ping" {
            sendPong()
            return
        }
        
        // Try to decode as TipioEvent
        guard let data = text.data(using: .utf8) else {
            print("❌ [TipioWS] Failed to convert text to data")
            return
        }
        
        handleDataMessage(data)
    }
    
    private func handleDataMessage(_ data: Data) {
        do {
            let event = try JSONDecoder().decode(TipioEvent.self, from: data)
            print("📡 [TipioWS] Received event: \(event.type.rawValue) for stream \(event.streamId)")
            eventSubject.send(event)
        } catch {
            print("❌ [TipioWS] Failed to decode event: \(error)")
        }
    }
    
    private func sendMessage(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message) else {
            print("❌ [TipioWS] Failed to serialize message")
            return
        }
        
        let wsMessage = URLSessionWebSocketTask.Message.data(data)
        webSocketTask?.send(wsMessage) { error in
            if let error = error {
                print("❌ [TipioWS] Send error: \(error)")
            }
        }
    }
    
    private func sendPong() {
        webSocketTask?.send(.string("pong")) { error in
            if let error = error {
                print("❌ [TipioWS] Pong error: \(error)")
            }
        }
    }
    
    private func startHeartbeat() {
        stopHeartbeat()
        
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sendHeartbeat()
            }
        }
        
        print("💓 [TipioWS] Heartbeat started (interval: \(heartbeatInterval)s)")
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func sendHeartbeat() {
        let heartbeat = [
            "action": "heartbeat",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        sendMessage(heartbeat)
    }
    
    private func handleConnectionError(_ error: Error) {
        print("❌ [TipioWS] Connection error: \(error)")
        updateConnectionStatus(.error(error.localizedDescription))
        
        stopHeartbeat()
        
        // Attempt reconnection if not at max attempts
        if reconnectAttempts < maxReconnectAttempts {
            scheduleReconnect()
        } else {
            print("❌ [TipioWS] Max reconnect attempts reached")
            updateConnectionStatus(.disconnected)
        }
    }
    
    private func scheduleReconnect() {
        stopReconnectTimer()
        
        updateConnectionStatus(.reconnecting)
        reconnectAttempts += 1
        
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0) // Exponential backoff, max 30s
        
        print("🔄 [TipioWS] Scheduling reconnect in \(delay)s (attempt \(reconnectAttempts)/\(maxReconnectAttempts))")
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.connect()
            }
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func resetReconnectAttempts() {
        reconnectAttempts = 0
        stopReconnectTimer()
    }
    
    private func updateConnectionStatus(_ status: ConnectionStatus) {
        connectionStatus = status
        isConnected = (status == .connected)
        connectionSubject.send(status)
        
        print("🔌 [TipioWS] Connection status: \(status.displayName)")
    }
    
    deinit {
        Task { @MainActor in
            self.disconnect()
        }
        print("🔌 [TipioWS] WebSocket client deinitialized")
    }
}

// MARK: - Error Types

public enum TipioWebSocketError: LocalizedError {
    case invalidURL
    case connectionFailed
    case authenticationFailed
    case messageDecodingFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .connectionFailed:
            return "WebSocket connection failed"
        case .authenticationFailed:
            return "WebSocket authentication failed"
        case .messageDecodingFailed:
            return "Failed to decode WebSocket message"
        }
    }
}
