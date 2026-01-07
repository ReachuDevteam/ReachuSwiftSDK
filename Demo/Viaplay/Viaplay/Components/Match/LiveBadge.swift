//
//  LiveBadge.swift
//  Viaplay
//
//  Atomic component: LIVE indicator badge
//

import SwiftUI

struct LiveBadge: View {
    let size: Size
    let showPulse: Bool
    
    enum Size {
        case small
        case medium
        case large
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }
        
        var dotSize: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 10
            }
        }
    }
    
    init(size: Size = .medium, showPulse: Bool = true) {
        self.size = size
        self.showPulse = showPulse
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: size.dotSize, height: size.dotSize)
                .opacity(showPulse ? 1.0 : 0.8)
            
            Text("LIVE")
                .font(.system(size: size.fontSize, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        LiveBadge(size: .small)
        LiveBadge(size: .medium)
        LiveBadge(size: .large)
    }
    .padding()
    .background(Color.black)
}


