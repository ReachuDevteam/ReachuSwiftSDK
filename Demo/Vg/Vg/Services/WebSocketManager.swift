import Foundation
import Combine
import ReachuCore

class WebSocketManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var currentPoll: PollEventData?
    @Published var currentProduct: ProductEventData?
    @Published var currentContest: ContestEventData?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private var pingTimer: Timer?
    
    override init() {
        super.init()
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    }
    
    func connect() {
        guard !isConnected else {
            print("🔌 [WebSocket] Ya está conectado, ignorando nueva conexión")
            return
        }
        
        // Obtener campaignId del config dinámicamente
        let campaignId = ReachuConfiguration.shared.liveShowConfiguration.campaignId
        let url = URL(string: "wss://dev-campaing.reachu.io/ws/\(campaignId)")!
        print("🔌 [WebSocket] Conectando a: \(url.absoluteString) (campaignId: \(campaignId))")
        print("🔌 [WebSocket] Verificando si hay eventos activos para campaignId: \(campaignId)")
        
        // Crear URLRequest con headers de autenticación
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        
        // Agregar API key a los headers si está disponible
        let config = ReachuConfiguration.shared
        if !config.apiKey.isEmpty {
            request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
            let apiKeyMasked = String(repeating: "*", count: max(0, config.apiKey.count - 4)) + config.apiKey.suffix(4)
            print("🔑 [WebSocket] Usando API Key: \(apiKeyMasked)")
        }
        
        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // No marcar como conectado hasta que el delegate confirme
        // receiveMessage() se llamará desde didOpenWithProtocol
        print("🔌 [WebSocket] WebSocketTask creado y resumido, esperando confirmación de conexión...")
    }
    
    func disconnect() {
        guard isConnected else { return }
        pingTimer?.invalidate()
        pingTimer = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        print("🔌 [WebSocket] Desconectado")
    }
    
    private func startPingTimer() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func sendPing() {
        guard let task = webSocketTask, isConnected else {
            print("⚠️ [WebSocket] No se puede enviar ping, socket no conectado")
            return
        }
        
        let pingMessage = URLSessionWebSocketTask.Message.string("ping")
        task.send(pingMessage) { error in
            if let error = error {
                print("❌ [WebSocket] Error enviando ping: \(error.localizedDescription)")
            } else {
                print("📤 [WebSocket] Ping enviado")
            }
        }
    }
    
    private func receiveMessage() {
        guard isConnected, webSocketTask != nil else {
            print("⚠️ [WebSocket] No se puede recibir mensajes, socket no conectado")
            return
        }
        print("👂 [WebSocket] Esperando mensaje...")
        webSocketTask?.receive { [weak self] result in
            guard let self = self else {
                print("⚠️ [WebSocket] Self es nil en receive callback")
                return
            }
            
            print("📥 [WebSocket] Callback recibido, procesando resultado...")
            
            switch result {
            case .success(let message):
                print("✅ [WebSocket] Mensaje recibido exitosamente")
                switch message {
                case .string(let text):
                    print("📩 [WebSocket] Mensaje recibido (string): \(text)")
                    self.handleMessage(text)
                case .data(let data):
                    print("📩 [WebSocket] Mensaje recibido (data), tamaño: \(data.count) bytes")
                    if let text = String(data: data, encoding: .utf8) {
                        print("📩 [WebSocket] Mensaje recibido (data convertido): \(text)")
                        self.handleMessage(text)
                    } else {
                        print("⚠️ [WebSocket] Mensaje recibido como data pero no se pudo convertir a String")
                        print("⚠️ [WebSocket] Primeros bytes: \(data.prefix(100).map { String(format: "%02x", $0) }.joined(separator: " "))")
                    }
                @unknown default:
                    print("⚠️ [WebSocket] Tipo de mensaje desconocido")
                }
                
                // Continuar recibiendo mensajes solo si seguimos conectados
                if self.isConnected {
                    print("🔄 [WebSocket] Continuando a recibir más mensajes...")
                    self.receiveMessage()
                } else {
                    print("⚠️ [WebSocket] No se continúa recibiendo mensajes, socket desconectado")
                }
                
            case .failure(let error):
                print("❌ [WebSocket] Error recibiendo mensaje: \(error.localizedDescription)")
                print("❌ [WebSocket] Error code: \((error as NSError).code)")
                print("❌ [WebSocket] Error domain: \((error as NSError).domain)")
                DispatchQueue.main.async {
                    self.isConnected = false
                    self.webSocketTask = nil
                }
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        print("🔍 [WebSocket] Procesando mensaje: \(text.prefix(200))...")
        
        guard let data = text.data(using: .utf8) else {
            print("❌ [WebSocket] No se pudo convertir texto a data UTF-8")
            return
        }
        
        print("🔍 [WebSocket] Data convertido, tamaño: \(data.count) bytes")
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ [WebSocket] No se pudo parsear JSON")
            print("❌ [WebSocket] Raw text: \(text)")
            return
        }
        
        print("✅ [WebSocket] JSON parseado correctamente")
        print("🔍 [WebSocket] Keys en JSON: \(json.keys.joined(separator: ", "))")
        
        guard let eventType = json["type"] as? String else {
            print("❌ [WebSocket] No se encontró 'type' en el JSON")
            print("❌ [WebSocket] JSON completo: \(json)")
            return
        }
        
        print("🎯 [WebSocket] Tipo de evento detectado: \(eventType)")
        
        do {
            switch eventType {
            case "product":
                print("🛍️ [WebSocket] Decodificando ProductEvent...")
                let event = try JSONDecoder().decode(ProductEvent.self, from: data)
                print("✅ [WebSocket] ProductEvent decodificado exitosamente")
                handleProductEvent(event)
            case "poll":
                print("📊 [WebSocket] Decodificando PollEvent...")
                let event = try JSONDecoder().decode(PollEvent.self, from: data)
                print("✅ [WebSocket] PollEvent decodificado exitosamente")
                handlePollEvent(event)
            case "contest":
                print("🎁 [WebSocket] Decodificando ContestEvent...")
                let event = try JSONDecoder().decode(ContestEvent.self, from: data)
                print("✅ [WebSocket] ContestEvent decodificado exitosamente")
                handleContestEvent(event)
            default:
                print("⚠️ [WebSocket] Tipo de evento desconocido: \(eventType)")
                print("⚠️ [WebSocket] JSON recibido: \(json)")
            }
        } catch {
            print("❌ [WebSocket] Error decodificando evento: \(error)")
            print("❌ [WebSocket] Error details: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                print("❌ [WebSocket] DecodingError details:")
                switch decodingError {
                case .dataCorrupted(let context):
                    print("   - Data corrupted: \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    print("   - Key not found: \(key.stringValue), context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("   - Type mismatch: \(type), context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("   - Value not found: \(type), context: \(context.debugDescription)")
                @unknown default:
                    print("   - Unknown decoding error")
                }
            }
            print("❌ [WebSocket] Raw message: \(text)")
        }
    }
    
    private func handleProductEvent(_ event: ProductEvent) {
        DispatchQueue.main.async {
            print("🛍️ [WebSocket] Producto recibido: \(event.data.name)")
            print("🛍️ [WebSocket] Product productId: \(event.data.productId)")
            print("🛍️ [WebSocket] Product campaignLogo en evento root: \(event.campaignLogo ?? "nil")")
            print("🛍️ [WebSocket] Product campaignLogo en data: \(event.data.campaignLogo ?? "nil")")
            var productData = event.data
            if productData.campaignLogo == nil && event.campaignLogo != nil {
                productData.campaignLogo = event.campaignLogo
                print("🛍️ [WebSocket] ✅ Copiado campaignLogo del root al data")
            }
            print("🛍️ [WebSocket] Product campaignLogo final: \(productData.campaignLogo ?? "nil")")
            print("🛍️ [WebSocket] Product imageUrl: \(productData.imageUrl)")
            print("🛍️ [WebSocket] Product price: \(productData.price)")
            self.currentProduct = productData
        }
    }
    
    private func handlePollEvent(_ event: PollEvent) {
        DispatchQueue.main.async {
            print("📊 [WebSocket] Poll recibido: \(event.data.question)")
            print("📊 [WebSocket] Poll campaignLogo en evento root: \(event.campaignLogo ?? "nil")")
            print("📊 [WebSocket] Poll campaignLogo en data: \(event.data.campaignLogo ?? "nil")")
            var pollData = event.data
            if pollData.campaignLogo == nil && event.campaignLogo != nil {
                pollData.campaignLogo = event.campaignLogo
                print("📊 [WebSocket] ✅ Copiado campaignLogo del root al data")
            }
            print("📊 [WebSocket] Poll campaignLogo final: \(pollData.campaignLogo ?? "nil")")
            print("📊 [WebSocket] Poll options count: \(pollData.options.count)")
            for (index, option) in pollData.options.enumerated() {
                print("📊 [WebSocket]   Option \(index): \(option.text), avatarUrl: \(option.avatarUrl ?? "nil")")
            }
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
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocolName: String?) {
        DispatchQueue.main.async {
            print("✅ [WebSocket] Delegate: Conexión abierta exitosamente")
            if let proto = protocolName {
                print("✅ [WebSocket] Protocol: \(proto)")
            } else {
                print("✅ [WebSocket] Protocol: nil")
            }
            self.isConnected = true
            print("✅ [WebSocket] Marcado como conectado, iniciando recepción de mensajes...")
            // Iniciar recepción de mensajes solo después de que el delegate confirme la conexión
            self.receiveMessage()
            // Iniciar ping periódico para mantener la conexión activa
            self.startPingTimer()
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async {
            print("🔌 [WebSocket] Delegate: Conexión cerrada")
            print("🔌 [WebSocket] Close code: \(closeCode.rawValue)")
            if let reasonData = reason, let reasonString = String(data: reasonData, encoding: .utf8) {
                print("🔌 [WebSocket] Close reason: \(reasonString)")
            }
            self.isConnected = false
            self.webSocketTask = nil
        }
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


