//
//  MatchSectionView.swift
//  Vg
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI

struct MatchSectionView: View {
    let section: MatchSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: VGTheme.Spacing.md) {
            // Section Header
            HStack {
                Text(section.title)
                    .font(VGTheme.Typography.headline())
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("SE ALLE")
                            .font(VGTheme.Typography.caption())
                            .foregroundColor(.white)
                        
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, VGTheme.Spacing.md)
            
            // Match Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: VGTheme.Spacing.md) {
                    ForEach(section.matches) { match in
                        MatchCard(match: match)
                            .frame(width: 180)
                    }
                }
                .padding(.horizontal, VGTheme.Spacing.md)
            }
        }
    }
}

#Preview {
    MatchSectionView(section: Match.mockMatches[0])
        .background(VGTheme.Colors.black)
}
