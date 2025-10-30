//
//  SportDetailView.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI
import ReachuCore
import ReachuUI

struct SportDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var cartManager: CartManager
    @Binding var selectedTab: Int
    let title: String
    let subtitle: String
    let imageUrl: String
    @State private var showVideoPlayer = false
    @StateObject private var castingManager = CastingManager.shared
    @State private var showCastDeviceSelection = false
    @State private var showCastingView = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background
                Color(hex: "1B1B25")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero section with image and overlays
                        ZStack(alignment: .topLeading) {
                            // Background image - use bg for Barcelona - PSG
                            Image("bg")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: 320)
                                .clipped()
                            
                            // Dark gradient overlay
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.clear,
                                    Color(hex: "1B1B25").opacity(0.3),
                                    Color(hex: "1B1B25").opacity(0.7),
                                    Color(hex: "1B1B25")
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(width: geometry.size.width, height: 320)
                            
                            // Header with back button and cast icon
                            HStack {
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                Button(action: { showCastDeviceSelection = true }) {
                                    Image(systemName: castingManager.isCasting ? "tv.fill" : "airplayvideo")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(castingManager.isCasting ? ViaplayTheme.Colors.pink : .white)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 44)
                            
                            // Content overlay (title, subtitle, progress bar)
                            VStack(spacing: 12) {
                                Spacer()
                                
                                // Title
                                Text(title)
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                // Subtitle
                                Text(subtitle)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                
                                // Progress bar
                                VStack(spacing: 6) {
                                    HStack {
                                        Text("14:00")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Spacer()
                                        
                                        Text("20:30")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    
                                    GeometryReader { progressGeometry in
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .fill(Color.white.opacity(0.2))
                                                .frame(height: 3)
                                            
                                            Rectangle()
                                                .fill(Color(red: 0.96, green: 0.08, blue: 0.42))
                                                .frame(width: progressGeometry.size.width * 0.4, height: 3)
                                        }
                                    }
                                    .frame(height: 3)
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                            }
                            .frame(width: geometry.size.width)
                        }
                        .frame(width: geometry.size.width, height: 320)
                        
                        // Action Buttons
                        VStack(spacing: 10) {
                            // Live button
                            Button(action: { showVideoPlayer = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 16, weight: .bold))
                                    
                                    Text("Live")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(width: geometry.size.width - 32)
                                .frame(height: 44)
                                .background(Color(red: 0.96, green: 0.08, blue: 0.42))
                                .cornerRadius(10)
                            }
                            
                            HStack(spacing: 10) {
                                // Previous button
                                Button(action: {}) {
                                    Image(systemName: "backward.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: (geometry.size.width - 42) / 2)
                                        .frame(height: 44)
                                        .background(Color(hex: "2C2D36"))
                                        .cornerRadius(10)
                                }
                                
                                // Share button
                                Button(action: {}) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 14, weight: .semibold))
                                        
                                        Text("Share")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(width: (geometry.size.width - 42) / 2)
                                    .frame(height: 44)
                                    .background(Color(hex: "2C2D36"))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    
                        // Event details
                        VStack(alignment: .leading, spacing: 14) {
                            DetailRow(icon: "clock", text: "Today 14:00")
                            DetailRow(icon: "mic", text: "Engelsk")
                            DetailRow(icon: "mappin.circle", text: "Newgiza Sports Club")
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Padel: Champions League")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Available to: 31 October at 20:30")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .frame(width: geometry.size.width, alignment: .leading)
                        
                        // Recommended section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Kommende innen Champions League")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .frame(width: geometry.size.width, alignment: .leading)
                            
                            // Live card
                            ZStack(alignment: .topLeading) {
                                Image("img1")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width - 32, height: 150)
                                    .clipped()
                                    .cornerRadius(10)
                                
                                Text("LIVE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(red: 0.96, green: 0.08, blue: 0.42))
                                    .cornerRadius(4)
                                    .padding(10)
                                
                                // Progress bar in card
                                VStack {
                                    Spacer()
                                    HStack {
                                        Text("14:00")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.bottom, 10)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 24)
                        .frame(width: geometry.size.width)
                        
                        // Products carousel from SDK
                        VStack(alignment: .leading, spacing: 10) {
                            // Header with title and sponsor badge
                            HStack(alignment: .top, spacing: 12) {
                                // Title
                                Text("Produkter")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Sponsor badge
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Sponset av")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Image("logo1")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 80, maxHeight: 24)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            RProductSlider(
                                title: nil,
                                layout: .cards
                            )
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 100)
                        .frame(width: geometry.size.width)
                    }
                }
                .ignoresSafeArea(edges: .top)
                
                // Bottom Navigation - Only show when video player is not showing
                if !showVideoPlayer {
                    VStack {
                        Spacer()
                        ViaplayBottomNav(selectedTab: $selectedTab)
                            .frame(width: geometry.size.width)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showVideoPlayer) {
            ViaplayVideoPlayer(match: createMatchFromDetail()) {
                showVideoPlayer = false
            }
            .environmentObject(cartManager)
        }
        .sheet(isPresented: $showCastDeviceSelection) {
            CastDeviceSelectionView { device in
                castingManager.startCasting(to: device)
                showCastingView = true
            }
        }
        .fullScreenCover(isPresented: $showCastingView) {
            ViaplayCastingActiveView(match: createMatchFromDetail())
                .environmentObject(cartManager)
        }
        .onChange(of: castingManager.isCasting) { isCasting in
            if !isCasting {
                showCastingView = false
            }
        }
    }
    
    // Helper para crear un Match desde los datos del SportDetailView
    private func createMatchFromDetail() -> Match {
        return Match(
            homeTeam: Team(name: "Team A", shortName: "TA", logo: "img1"),
            awayTeam: Team(name: "Team B", shortName: "TB", logo: "img1"),
            title: title,
            subtitle: subtitle,
            competition: subtitle,
            venue: "Venue",
            commentator: nil,
            isLive: true,
            backgroundImage: imageUrl,
            availability: .available,
            relatedContent: [],
            campaignLogo: nil
        )
    }
}

struct DetailRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SportDetailView(
        selectedTab: .constant(1),
        title: "Lorient - PSG",
        subtitle: "Ligue 1 | 10. runde",
        imageUrl: "img1"
    )
}

