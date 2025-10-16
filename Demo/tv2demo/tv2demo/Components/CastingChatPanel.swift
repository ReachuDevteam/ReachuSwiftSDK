import SwiftUI

/// Versión simplificada del chat específica para la vista de casting
struct CastingChatPanel: View {
    @ObservedObject var chatManager: ChatManager
    @State private var messageText = ""
    @State private var isExpanded = false
    
    private let collapsedHeight: CGFloat = 40
    private let expandedHeight: CGFloat = 200
    
    var body: some View {
        VStack(spacing: 0) {
            // Header / Drag handle
            chatHeader
            
            // Chat messages (solo cuando está expandido)
            if isExpanded {
                chatMessages
            }
        }
        .frame(height: isExpanded ? expandedHeight : collapsedHeight)
        .frame(maxWidth: 500)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .background(.ultraThinMaterial)
        )
        .cornerRadius(12)
        .animation(.spring(response: 0.3), value: isExpanded)
    }
    
    // MARK: - Chat Header
    
    private var chatHeader: some View {
        Button(action: {
            isExpanded.toggle()
        }) {
            HStack {
                Image(systemName: "message.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                
                Text("LIVE CHAT")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Text("(\(chatManager.messages.count))")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(height: collapsedHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Chat Messages
    
    private var chatMessages: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.2))
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(chatManager.messages.suffix(10)) { message in
                            chatMessageRow(message)
                                .id(message.id)
                        }
                    }
                    .padding(12)
                }
                .frame(height: expandedHeight - collapsedHeight - 50)
                .onChange(of: chatManager.messages.count) { _ in
                    if let lastMessage = chatManager.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Input bar
            chatInputBar
        }
    }
    
    private func chatMessageRow(_ message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(message.usernameColor)
                    .frame(width: 24, height: 24)
                
                Text(message.username.prefix(1).uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Message content
            VStack(alignment: .leading, spacing: 2) {
                Text(message.username)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(message.usernameColor)
                
                Text(message.text)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Input Bar
    
    private var chatInputBar: some View {
        HStack(spacing: 8) {
            TextField("Mensaje...", text: $messageText)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.15))
                )
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 14))
                    .foregroundColor(messageText.isEmpty ? .white.opacity(0.3) : TV2Theme.Colors.primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(messageText.isEmpty ? Color.white.opacity(0.1) : TV2Theme.Colors.primary.opacity(0.2))
                    )
            }
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(height: 50)
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newMessage = ChatMessage(
            username: "Angelo",
            text: messageText,
            usernameColor: TV2Theme.Colors.secondary,
            likes: 0,
            timestamp: Date()
        )
        
        chatManager.addMessage(newMessage)
        messageText = ""
    }
}

#Preview {
    ZStack {
        Color.black
        
        VStack {
            Spacer()
            CastingChatPanel(chatManager: ChatManager())
                .padding()
        }
    }
}

