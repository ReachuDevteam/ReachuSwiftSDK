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
    
    init(messages: [ChatMessage], viewerCount: Int = 0, selectedMinute: Int? = nil, compact: Bool = false) {
        self.messages = messages
        self.viewerCount = viewerCount
        self.selectedMinute = selectedMinute
        self.compact = compact
    }
    
    private var title: String {
        if let minute = selectedMinute {
            return "Chat at \(minute)'"
        }
        return "Live Chat"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if selectedMinute == nil && viewerCount > 0 {
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
                
                // Messages
                ForEach(messages) { message in
                    ChatMessageRow(message: message, compact: compact)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
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


