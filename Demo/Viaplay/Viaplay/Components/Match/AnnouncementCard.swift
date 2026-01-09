//
//  AnnouncementCard.swift
//  Viaplay
//
//  Molecular component: Announcement card
//

import SwiftUI

struct AnnouncementCard: View {
    let announcement: AnnouncementEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and title
            HStack(spacing: 8) {
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.96, green: 0.08, blue: 0.42))
                
                Text(announcement.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Message
            Text(announcement.message)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            
            // Action button if available
            if let actionText = announcement.actionText {
                Button(action: {}) {
                    Text(actionText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.96, green: 0.08, blue: 0.42))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        AnnouncementCard(
            announcement: AnnouncementEvent(
                id: "kickoff",
                videoTimestamp: 0,
                title: "⚽ Avspark",
                message: "Kampen starter! Barcelona vs PSG",
                imageUrl: nil,
                actionUrl: nil,
                actionText: nil,
                metadata: nil
            )
        )
        
        AnnouncementCard(
            announcement: AnnouncementEvent(
                id: "halftime",
                videoTimestamp: 2700,
                title: "⏸ Pause",
                message: "Første omgang ferdig. Stillingen er 2-0 til Barcelona.",
                imageUrl: nil,
                actionUrl: nil,
                actionText: "Se høydepunkter",
                metadata: nil
            )
        )
    }
    .padding()
    .background(Color(hex: "1B1B25"))
}
