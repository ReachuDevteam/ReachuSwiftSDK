//
//  SponsorBanner.swift
//  Viaplay
//
//  Molecular component: Sponsor banner
//

import SwiftUI

struct SponsorBanner: View {
    let logoName: String
    let text: String
    
    init(logoName: String = "logo1", text: String = "Sponset av") {
        self.logoName = logoName
        self.text = text
    }
    
    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Image(logoName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 20)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "1F1E26"))
    }
}

#Preview {
    VStack(spacing: 0) {
        SponsorBanner()
        SponsorBanner(logoName: "logo1", text: "Presented by")
    }
}


