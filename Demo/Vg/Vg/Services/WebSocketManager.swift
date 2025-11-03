import Foundation
import Combine

class WebSocketManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var currentPoll: PollEventData?
    @Published var currentProduct: ProductEventData?
    @Published var currentContest: ContestEventData?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    
    override init() {
        super.init()
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    }
    
    func connect() {
        guard !isConnected else { return }
        let url = URL(string: "wss://event-streamer-angelo100.replit.app/ws/3")!
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        receiveMessage()
    }
    
    func disconnect() {
        guard isConnected else { return }
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }
    
    private func receiveMessage() {
        guard isConnected, webSocketTask != nil else { return }
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text): self.handleMessage(text)
                case .data(let data): if let text = String(data: data, encoding: .utf8) { self.handleMessage(text) }
                @unknown default: break
                }
                if self.isConnected { self.receiveMessage() }
            case .failure:
                DispatchQueue.main.async { self.isConnected = false; self.webSocketTask = nil }
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let eventType = json["type"] as? String else { return }
        do {
            switch eventType {
            case "product":
                let event = try JSONDecoder().decode(ProductEvent.self, from: data)
                handleProductEvent(event)
            case "poll":
                let event = try JSONDecoder().decode(PollEvent.self, from: data)
                handlePollEvent(event)
            case "contest":
                let event = try JSONDecoder().decode(ContestEvent.self, from: data)
                handleContestEvent(event)
            default: break
            }
        } catch {
        }
    }
    
    private func handleProductEvent(_ event: ProductEvent) {
        DispatchQueue.main.async {
            var productData = event.data
            if productData.campaignLogo == nil && event.campaignLogo != nil { productData.campaignLogo = event.campaignLogo }
            self.currentProduct = productData
        }
    }
    
    private func handlePollEvent(_ event: PollEvent) {
        DispatchQueue.main.async {
            var pollData = event.data
            if pollData.campaignLogo == nil && event.campaignLogo != nil { pollData.campaignLogo = event.campaignLogo }
            self.currentPoll = pollData
        }
    }
    
    private func handleContestEvent(_ event: ContestEvent) {
        DispatchQueue.main.async {
            var contestData = event.data
            if contestData.campaignLogo == nil && event.campaignLogo != nil { contestData.campaignLogo = event.campaignLogo }
            self.currentContest = contestData
        }
    }
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async { self.isConnected = true }
    }
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async { self.isConnected = false }
    }
}

struct ProductEvent: Codable { let type: String; let data: ProductEventData; let campaignLogo: String?; let timestamp: Int64 }
struct ProductEventData: Codable, Equatable { let id: String; let productId: String; let name: String; let description: String; let price: String; let currency: String; let imageUrl: String; var campaignLogo: String? }
struct PollEvent: Codable { let type: String; let data: PollEventData; let campaignLogo: String?; let timestamp: Int64 }
struct PollEventData: Codable, Identifiable, Equatable { let id: String; let question: String; let options: [PollOption]; let duration: Int; let imageUrl: String?; var campaignLogo: String? }
struct PollOption: Codable, Identifiable, Equatable {
    let id = UUID()
    let text: String
    let avatarUrl: String?
    enum CodingKeys: String, CodingKey { case text; case avatarUrl; case imageUrl }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        if let url = try container.decodeIfPresent(String.self, forKey: .avatarUrl) { avatarUrl = url } else { avatarUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl) }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(avatarUrl, forKey: .avatarUrl)
    }
    init(text: String, avatarUrl: String?) { self.text = text; self.avatarUrl = avatarUrl }
}
struct ContestEvent: Codable { let type: String; let data: ContestEventData; let campaignLogo: String?; let timestamp: Int64 }
struct ContestEventData: Codable, Equatable { let id: String; let name: String; let prize: String; let deadline: String; let maxParticipants: Int; var campaignLogo: String? }


