//
//  ReactionButton.swift
//  Viaplay
//
//  Atomic component: Emoji reaction button with count
//

import SwiftUI

struct ReactionButton: View {
    let emoji: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    init(emoji: String, count: Int, isSelected: Bool = false, action: @escaping () -> Void = {}) {
        self.emoji = emoji
        self.count = count
        self.isSelected = isSelected
        self.action = action
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        }
        return "\(count)"
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 16))
                
                Text(formatCount(count))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
            )
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        ReactionButton(emoji: "🔥", count: 3456)
        ReactionButton(emoji: "❤️", count: 2345, isSelected: true)
        ReactionButton(emoji: "⚽", count: 1234)
    }
    .padding()
    .background(Color.black)
}


