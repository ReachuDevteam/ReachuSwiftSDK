import Foundation
import Combine

/// Manager para conexión WebSocket con servidor de eventos
/// URL: wss://event-streamer-angelo100.replit.app/ws
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
        let url = URL(string: "wss://event-streamer-angelo100.replit.app/ws")!
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        print("🔌 [WebSocket] Conectando a: \(url.absoluteString)")
        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        print("🔌 [WebSocket] Desconectado")
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("📩 [WebSocket] Mensaje recibido: \(text)")
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        print("📩 [WebSocket] Mensaje recibido (data): \(text)")
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                // Continuar recibiendo mensajes
                self?.receiveMessage()
                
            case .failure(let error):
                print("❌ [WebSocket] Error: \(error.localizedDescription)")
                self?.isConnected = false
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        // Primero, obtener el tipo de evento
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let eventType = json["type"] as? String
        else {
            print("❌ [WebSocket] No se pudo parsear el tipo de evento")
            return
        }
        
        // Decodificar según el tipo
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
            default:
                print("⚠️ [WebSocket] Tipo de evento desconocido: \(eventType)")
            }
        } catch {
            print("❌ [WebSocket] Error decodificando evento: \(error)")
        }
    }
    
    private func handleProductEvent(_ event: ProductEvent) {
        DispatchQueue.main.async {
            print("🛍️ [WebSocket] Producto recibido: \(event.data.name)")
            self.currentProduct = event.data
        }
    }
    
    private func handlePollEvent(_ event: PollEvent) {
        DispatchQueue.main.async {
            print("📊 [WebSocket] Poll recibido: \(event.data.question)")
            self.currentPoll = event.data
        }
    }
    
    private func handleContestEvent(_ event: ContestEvent) {
        DispatchQueue.main.async {
            print("🎁 [WebSocket] Concurso recibido: \(event.data.name)")
            self.currentContest = event.data
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async {
            self.isConnected = true
            print("✅ [WebSocket] Conectado exitosamente")
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async {
            self.isConnected = false
            print("🔌 [WebSocket] Conexión cerrada. Código: \(closeCode.rawValue)")
        }
    }
}

// MARK: - Event Models

struct ProductEvent: Codable {
    let type: String
    let data: ProductEventData
    let timestamp: Int64
}

struct ProductEventData: Codable {
    let id: String
    let name: String
    let description: String
    let price: String
    let currency: String
    let imageUrl: String
}

struct PollEvent: Codable {
    let type: String
    let data: PollEventData
    let timestamp: Int64
}

struct PollEventData: Codable, Identifiable, Equatable {
    let id: String
    let question: String
    let options: [String]
    let duration: Int
}

struct ContestEvent: Codable {
    let type: String
    let data: ContestEventData
    let timestamp: Int64
}

struct ContestEventData: Codable {
    let id: String
    let name: String
    let prize: String
    let deadline: String
    let maxParticipants: Int
}

