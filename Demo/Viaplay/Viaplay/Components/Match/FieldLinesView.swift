//
//  FieldLinesView.swift
//  Viaplay
//
//  Football field lines (center circle, penalty areas, goals)
//

import SwiftUI

struct FieldLinesView: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                // Outer border
                Rectangle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    .padding(8)
                
                // Bottom line (was center line - now at bottom for half field)
                Path { path in
                    path.move(to: CGPoint(x: 8, y: height - 8))
                    path.addLine(to: CGPoint(x: width - 8, y: height - 8))
                }
                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                
                // Center circle (at bottom for half field)
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    .frame(width: min(width, height) * 0.35)
                    .position(x: width / 2, y: height - 8)
                    .clipped()
                
                // Top penalty area
                Path { path in
                    let areaWidth = width * 0.6
                    let areaHeight = height * 0.15
                    let startX = (width - areaWidth) / 2
                    
                    path.move(to: CGPoint(x: startX, y: 8))
                    path.addLine(to: CGPoint(x: startX, y: areaHeight))
                    path.addLine(to: CGPoint(x: startX + areaWidth, y: areaHeight))
                    path.addLine(to: CGPoint(x: startX + areaWidth, y: 8))
                }
                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                
                // Top goal area (smaller)
                Path { path in
                    let goalWidth = width * 0.35
                    let goalHeight = height * 0.08
                    let startX = (width - goalWidth) / 2
                    
                    path.move(to: CGPoint(x: startX, y: 8))
                    path.addLine(to: CGPoint(x: startX, y: goalHeight))
                    path.addLine(to: CGPoint(x: startX + goalWidth, y: goalHeight))
                    path.addLine(to: CGPoint(x: startX + goalWidth, y: 8))
                }
                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                
                // Bottom penalty area
                Path { path in
                    let areaWidth = width * 0.6
                    let areaHeight = height * 0.15
                    let startX = (width - areaWidth) / 2
                    let startY = height - areaHeight
                    
                    path.move(to: CGPoint(x: startX, y: height - 8))
                    path.addLine(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: startX + areaWidth, y: startY))
                    path.addLine(to: CGPoint(x: startX + areaWidth, y: height - 8))
                }
                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                
                // Bottom goal area (smaller)
                Path { path in
                    let goalWidth = width * 0.35
                    let goalHeight = height * 0.08
                    let startX = (width - goalWidth) / 2
                    let startY = height - goalHeight
                    
                    path.move(to: CGPoint(x: startX, y: height - 8))
                    path.addLine(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: startX + goalWidth, y: startY))
                    path.addLine(to: CGPoint(x: startX + goalWidth, y: height - 8))
                }
                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                
                // Penalty spots
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .position(x: width / 2, y: height * 0.12)
                
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .position(x: width / 2, y: height * 0.88)
            }
        }
    }
}

#Preview {
    FieldLinesView()
        .frame(width: 300, height: 450)
        .background(Color.black)
}
