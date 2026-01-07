//
//  ChatMessageRow.swift
//  Viaplay
//
//  Molecular component: Chat message row
//

import SwiftUI

struct ChatMessageRow: View {
    let message: ChatMessage
    let compact: Bool
    
    init(message: ChatMessage, compact: Bool = false) {
        self.message = message
        self.compact = compact
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ChatAvatar(
                initial: message.avatarInitial,
                color: message.usernameColor,
                size: compact ? 28 : 32
            )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(message.username)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(message.usernameColor)
                        .lineLimit(1)
                    
                    Text(message.timeAgo())
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                }
                
                Text(message.text)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let message1 = ChatMessage(
        username: "MatchMaster",
        text: "Beste kampen denne sesongen",
        usernameColor: .orange,
        likes: 5,
        timestamp: Date().addingTimeInterval(-20)
    )
    
    let message2 = ChatMessage(
        username: "SportsFan23",
        text: "KJØR PÅ!!!",
        usernameColor: .cyan,
        likes: 3,
        timestamp: Date().addingTimeInterval(-45)
    )
    
    return VStack(spacing: 12) {
        ChatMessageRow(message: message1)
        ChatMessageRow(message: message2, compact: true)
    }
    .padding()
    .background(Color.black)
}


