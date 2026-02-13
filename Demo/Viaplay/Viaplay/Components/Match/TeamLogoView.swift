//
//  TeamLogoView.swift
//  Viaplay
//
//  Atomic component: Team logo with name
//

import SwiftUI
import ReachuCastingUI

struct TeamLogoView: View {
    let team: Team
    let size: CGFloat
    let imageUrl: String?
    
    init(team: Team, size: CGFloat = 60, imageUrl: String? = nil) {
        self.team = team
        self.size = size
        self.imageUrl = imageUrl
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Group {
                if let url = imageUrl.flatMap(URL.init), url.absoluteString.hasPrefix("http") {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: { logoPlaceholder }
                } else if !team.logo.isEmpty {
                    Image(team.logo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    logoPlaceholder
                }
            }
            .frame(width: size, height: size)
            
            Text(team.name)
                .font(.system(size: 11, weight: .medium))  // Fixed size instead of relative
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var logoPlaceholder: some View {
        Circle()
            .fill(Color.blue.opacity(0.3))
            .overlay(
                Text(team.shortName)
                    .font(.system(size: size * 0.233, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}

#Preview {
    HStack(spacing: 32) {
        TeamLogoView(
            team: Team(name: "FC Barcelona", shortName: "FCB", logo: ""),
            imageUrl: "https://upload.wikimedia.org/wikipedia/en/thumb/4/47/FC_Barcelona_%28crest%29.svg/200px-FC_Barcelona_%28crest%29.svg.png"
        )
        
        TeamLogoView(
            team: Team(name: "PSG", shortName: "PSG", logo: ""),
            size: 80
        )
    }
    .padding()
    .background(Color.black)
}


