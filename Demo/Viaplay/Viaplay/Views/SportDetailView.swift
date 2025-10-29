//
//  SportDetailView.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI

struct SportDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let title: String
    let subtitle: String
    let imageUrl: String
    @State private var showVideoPlayer = false
    @StateObject private var cartManager = CartManager()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero section with image and overlays
                        ZStack(alignment: .topLeading) {
                            // Background image - use img1 for all images
                            Image("img1")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: 400)
                                .clipped()
                            
                            // Dark gradient overlay
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.2),
                                    Color.black.opacity(0.4),
                                    Color.black.opacity(0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(width: geometry.size.width, height: 400)
                            
                            // Header with back button and cast icon
                            HStack {
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                Button(action: {}) {
                                    Image(systemName: "airplayvideo")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 50)
                            
                            // Content overlay (title, subtitle, progress bar)
                            VStack(spacing: 16) {
                                Spacer()
                                
                                // Title
                                Text(title)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                // Subtitle
                                Text(subtitle)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                
                                // Progress bar
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("14:00")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Spacer()
                                        
                                        Text("20:30")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    
                                    GeometryReader { progressGeometry in
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .fill(Color.white.opacity(0.2))
                                                .frame(height: 4)
                                            
                                            Rectangle()
                                                .fill(Color(red: 0.96, green: 0.08, blue: 0.42))
                                                .frame(width: progressGeometry.size.width * 0.4, height: 4)
                                        }
                                    }
                                    .frame(height: 4)
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 30)
                            }
                            .frame(width: geometry.size.width)
                        }
                        .frame(width: geometry.size.width, height: 400)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            // Live button
                            Button(action: { showVideoPlayer = true }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 18, weight: .bold))
                                    
                                    Text("Live")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(width: geometry.size.width - 32)
                                .frame(height: 52)
                                .background(Color(red: 0.96, green: 0.08, blue: 0.42))
                                .cornerRadius(10)
                            }
                            
                            HStack(spacing: 12) {
                                // Previous button
                                Button(action: {}) {
                                    Image(systemName: "backward.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: (geometry.size.width - 44) / 2)
                                        .frame(height: 52)
                                        .background(Color(hex: "2C2D36"))
                                        .cornerRadius(10)
                                }
                                
                                // Share button
                                Button(action: {}) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 16, weight: .semibold))
                                        
                                        Text("Share")
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(width: (geometry.size.width - 44) / 2)
                                    .frame(height: 52)
                                    .background(Color(hex: "2C2D36"))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    
                        // Event details
                        VStack(alignment: .leading, spacing: 18) {
                            DetailRow(icon: "clock", text: "Today 14:00")
                            DetailRow(icon: "mic", text: "Engelsk")
                            DetailRow(icon: "mappin.circle", text: "Newgiza Sports Club")
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Padel: Premier Padel")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Available to: 31 October at 20:30")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 30)
                        .frame(width: geometry.size.width)
                        
                        // Recommended section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Kommende innen Premier Padel")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .frame(width: geometry.size.width, alignment: .leading)
                            
                            // Live card
                            ZStack(alignment: .topLeading) {
                                Image("img1")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width - 32, height: 180)
                                    .clipped()
                                    .cornerRadius(10)
                                
                                Text("LIVE")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(red: 0.96, green: 0.08, blue: 0.42))
                                    .cornerRadius(5)
                                    .padding(12)
                                
                                // Progress bar in card
                                VStack {
                                    Spacer()
                                    HStack {
                                        Text("14:00")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.bottom, 12)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 30)
                        .padding(.bottom, 100)
                        .frame(width: geometry.size.width)
                    }
                }
                .ignoresSafeArea(edges: .top)
                
                // Bottom Navigation
                VStack {
                    Spacer()
                    ViaplayBottomNav(selectedTab: .constant(1)) // Sport tab selected
                        .frame(width: geometry.size.width)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showVideoPlayer) {
            ViaplayVideoPlayer(match: Match.barcelonaPSG) {
                showVideoPlayer = false
            }
            .environmentObject(cartManager)
        }
    }
}

struct DetailRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 22)
            
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    SportDetailView(
        title: "Lorient - PSG",
        subtitle: "Ligue 1 | 10. runde",
        imageUrl: "img1"
    )
}

