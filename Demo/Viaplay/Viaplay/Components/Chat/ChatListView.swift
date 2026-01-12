//
//  ChatListView.swift
//  Viaplay
//
//  Organism component: Chat messages list
//

import SwiftUI

struct ChatListView: View {
    let messages: [ChatMessage]
    let viewerCount: Int
    let selectedMinute: Int?
    let compact: Bool
    let canChat: Bool
    let onSendMessage: ((String) -> Void)?
    
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    
    init(
        messages: [ChatMessage],
        viewerCount: Int = 0,
        selectedMinute: Int? = nil,
        compact: Bool = false,
        canChat: Bool = true,
        onSendMessage: ((String) -> Void)? = nil
    ) {
        self.messages = messages
        self.viewerCount = viewerCount
        self.selectedMinute = selectedMinute
        self.compact = compact
        self.canChat = canChat
        self.onSendMessage = onSendMessage
    }
    
    private var title: String {
        if let minute = selectedMinute {
            return "Chat ved \(minute)'"
        }
        return "Live Chat"
    }
    
    private var isLive: Bool {
        selectedMinute == nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages scroll view
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        // Header
                        HStack {
                            Text(title)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if isLive && viewerCount > 0 {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                    Text("\(viewerCount)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        
                        // Messages (oldest to newest - antiguos arriba, nuevos abajo)
                        ForEach(messages) { message in
                            ChatMessageRow(message: message, compact: compact)
                                .padding(.horizontal, 16)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }
                    .padding(.bottom, canChat && isLive ? 80 : 12)
                }
                .onChange(of: messages.count) { _ in
                    // Auto-scroll to newest message (at bottom)
                    if let lastMessage = messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Chat input (only in LIVE mode)
            if canChat && isLive {
                ChatInputBar(
                    messageText: $messageText,
                    isFocused: $isInputFocused,
                    onSend: {
                        guard !messageText.isEmpty else { return }
                        onSendMessage?(messageText)
                        messageText = ""
                        isInputFocused = false
                    },
                    onLike: {
                        // Send like animation
                    }
                )
            }
        }
        .background(Color(hex: "1B1B25"))
    }
}

#Preview {
    ChatListView(
        messages: [
            ChatMessage(username: "MatchMaster", text: "Beste kampen!", usernameColor: .orange, likes: 5, timestamp: Date()),
            ChatMessage(username: "SportsFan23", text: "KJØR PÅ!!!", usernameColor: .cyan, likes: 3, timestamp: Date().addingTimeInterval(-30))
        ],
        viewerCount: 1234
    )
}


