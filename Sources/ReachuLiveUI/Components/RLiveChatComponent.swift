import SwiftUI
import ReachuCore
import ReachuLiveShow
import ReachuDesignSystem

/// Reusable Live Chat component for LiveShow overlays
public struct RLiveChatComponent: View {
    
    // MARK: - Properties
    @ObservedObject private var chatManager: LiveChatManager
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var messageText = ""
    @State private var showChat = true
    @State private var userNameInput = ""
    @State private var showUserNameInput = false
    
    // Colors based on theme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    public init(channel: String? = nil, role: String = "USER", chatManager: LiveChatManager? = nil) {
        self.chatManager = chatManager ?? LiveChatManager.shared
        if let channel = channel {
            self.chatManager.configure(channel: channel, role: role)
        }
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(spacing: 0) {
            if showChat {
                // Chat messages with fading gradient background (no header)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                            ForEach(chatManager.messages) { message in
                                chatMessageView(message: message)
                            }
                        }
                        .padding(.horizontal, ReachuSpacing.md)
                        .padding(.vertical, ReachuSpacing.sm)
                    }
                    .frame(maxHeight: 120)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.6),
                                Color.black.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .onChange(of: chatManager.messages.count) { _ in
                        // Auto-scroll to last message
                        if let lastMessage = chatManager.messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Chat input
            HStack(spacing: ReachuSpacing.sm) {
                // Toggle chat visibility
                Button(action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showChat.toggle() 
                    }
                }) {
                    Image(systemName: showChat ? "chevron.down" : "chevron.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                
                // Conditional input: username first, then message
                if chatManager.hasUserName {
                    // Message input
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, ReachuSpacing.md)
                        .padding(.vertical, ReachuSpacing.sm)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Send button
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(messageText.isEmpty ? .gray : .white)
                            .frame(width: 32, height: 32)
                            .background(messageText.isEmpty ? Color.gray.opacity(0.3) : adaptiveColors.primary)
                            .clipShape(Circle())
                    }
                    .disabled(messageText.isEmpty)
                } else {
                    // Username input
                    TextField("Enter your name or alias", text: $userNameInput)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, ReachuSpacing.md)
                        .padding(.vertical, ReachuSpacing.sm)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    Button(action: setUserName) {
                        Text("Join")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(userNameInput.isEmpty ? .gray : .white)
                            .padding(.horizontal, ReachuSpacing.md)
                            .padding(.vertical, ReachuSpacing.sm)
                            .background(userNameInput.isEmpty ? Color.gray.opacity(0.3) : adaptiveColors.primary)
                            .cornerRadius(20)
                    }
                    .disabled(userNameInput.isEmpty)
                }
            }
            .padding(.horizontal, ReachuSpacing.md)
            .padding(.vertical, ReachuSpacing.sm)
            .padding(.bottom, 0) // Remove bottom padding to reach edge
            .background(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea(.container, edges: .bottom) // Extend to screen bottom
        }
    }
    
    // MARK: - Chat Message View
    
    @ViewBuilder
    private func chatMessageView(message: LiveChatMessage) -> some View {
        HStack(alignment: .top, spacing: ReachuSpacing.xs) {

            // MARK: - Avatar
            if let avatarUrl = message.user.avatarUrl, !avatarUrl.isEmpty,
            let url = URL(string: avatarUrl) {
                // Si existe avatar real
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 16, height: 16)
                .clipShape(Circle())

            } else {
                // Si no hay avatar URL → inicial con color basado en el nombre
                Circle()
                    .fill(colorForUsername(message.user.username))
                    .overlay(
                        Text(String(message.user.username.prefix(1)).uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .frame(width: 16, height: 16)
            }

            // MARK: - Username + Message
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: ReachuSpacing.xs) {
                    Text(message.user.username)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(getUsernameColor(for: message))

                    if message.user.isModerator {
                        Text("MOD")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                Text(message.message)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }

    // MARK: - Utilidad para color estable por usuario
    private func colorForUsername(_ username: String) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .pink, .purple, .red, .teal, .yellow]
        let hash = abs(username.hashValue)
        return colors[hash % colors.count]
    }

    // MARK: - Helper Methods
    
    private func getUsernameColor(for message: LiveChatMessage) -> Color {
        if message.isStreamerMessage {
            return Color.red // Streamer messages in red
        } else if message.user.isModerator {
            return Color.yellow // Moderator messages in yellow
        } else {
            return Color.white.opacity(0.9) // Regular users (no verified badge)
        }
    }
    
    private func setUserName() {
        guard !userNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        chatManager.setUserName(userNameInput)
        userNameInput = ""
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        chatManager.sendMessage(messageText)
        messageText = ""
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Spacer()
            RLiveChatComponent()
        }
    }
}
