//
//  ChatModels.swift
//  Viaplay
//
//  Chat data models - extracted for reusability
//

import Foundation
import SwiftUI

// MARK: - Chat Message

struct ChatMessage: Identifiable {
    let id = UUID()
    let username: String
    let text: String
    let usernameColor: Color
    let likes: Int
    let timestamp: Date
}

// MARK: - Helper Extensions

extension ChatMessage {
    /// Time ago from now (e.g., "5s", "2m", "1h")
    func timeAgo() -> String {
        let seconds = Int(Date().timeIntervalSince(timestamp))
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        return "\(hours)h"
    }
    
    /// First letter of username for avatar
    var avatarInitial: String {
        String(username.prefix(1))
    }
}


