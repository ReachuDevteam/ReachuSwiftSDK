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
    
    // Colors based on theme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    public init(chatManager: LiveChatManager? = nil) {
        self.chatManager = chatManager ?? LiveChatManager.shared
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(spacing: 0) {
            if showChat {
                // Chat header
                HStack {
                    Text("Live Chat")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(chatManager.messages.count) messages")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, ReachuSpacing.md)
                .padding(.vertical, ReachuSpacing.sm)
                .background(Color.black.opacity(0.8))
                
                // Chat messages with gradient background
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
                                Color.black.opacity(0.7),
                                Color.black.opacity(0.5),
                                Color.black.opacity(0.3)
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
            }
            .padding(.horizontal, ReachuSpacing.md)
            .padding(.vertical, ReachuSpacing.sm)
            .padding(.bottom, 0) // Remove bottom padding to reach edge
            .background(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.6),
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
            // User avatar (optional)
            if let avatarUrl = message.user.avatarUrl, !avatarUrl.isEmpty {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 16, height: 16)
                .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                // Username with admin badges only
                HStack(spacing: ReachuSpacing.xs) {
                    Text(message.user.username)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(getUsernameColor(for: message))
                    
                    // Only show MOD badge for admins/moderators
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
                
                // Message text
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
