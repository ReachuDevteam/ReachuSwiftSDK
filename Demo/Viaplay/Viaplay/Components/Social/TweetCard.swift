//
//  TweetCard.swift
//  Viaplay
//
//  Molecular component: Tweet card with reactions
//  Style based on X/Twitter posts
//

import SwiftUI

struct TweetCard: View {
    let tweet: TweetEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with avatar and info
            HStack(spacing: 12) {
                // Avatar
                AsyncImage(url: URL(string: tweet.authorAvatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .overlay(
                            Text(String(tweet.authorName.prefix(1)))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(tweet.authorName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        
                        if tweet.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Text("via X")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Text(timeAgo(from: tweet.videoTimestamp))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
            }
            
            // Tweet text
            Text(tweet.tweetText)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            // Reactions row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ReactionCount(emoji: "🔥", count: formatCount(tweet.likes / 4))
                    ReactionCount(emoji: "❤️", count: formatCount(tweet.likes / 5))
                    ReactionCount(emoji: "⚽", count: formatCount(tweet.retweets))
                    ReactionCount(emoji: "🏆", count: formatCount(tweet.likes / 8))
                    ReactionCount(emoji: "👍", count: formatCount(tweet.likes / 6))
                    ReactionCount(emoji: "🎯", count: formatCount(tweet.likes / 12))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Helpers
    
    private func timeAgo(from videoTimestamp: TimeInterval) -> String {
        let currentTime = Date()
        let messageTime = currentTime.addingTimeInterval(-videoTimestamp)
        let seconds = Int(currentTime.timeIntervalSince(messageTime))
        
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        return "\(hours)t"
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}

// MARK: - Reaction Count

private struct ReactionCount: View {
    let emoji: String
    let count: String
    
    var body: some View {
        HStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 18))
            Text(count)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

#Preview {
    TweetCard(
        tweet: TweetEvent(
            id: "tweet-1",
            videoTimestamp: 810,
            authorName: "Luka Modrić",
            authorHandle: "@LukaModric10",
            authorAvatar: "https://pbs.twimg.com/profile_images/1234/avatar.jpg",
            tweetText: "Nikada ne odustaj! ⚽🔥 #ChampionsLeague",
            isVerified: true,
            likes: 1345,
            retweets: 878,
            metadata: nil
        )
    )
    .padding()
    .background(Color.black)
}
