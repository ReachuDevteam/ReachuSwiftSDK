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
    
    var body: some View {
        ZStack(alignment: .top) {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Hero section with image and overlays
                    ZStack(alignment: .topLeading) {
                        // Background image
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                        }
                        .frame(height: 380)
                        .clipped()
                        
                        // Dark gradient overlay
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.3),
                                Color.black.opacity(0.5),
                                Color.black.opacity(0.8),
                                Color.black
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 380)
                        
                        // Back button
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Circle()
                                .fill(Color(hex: "2C2D36").opacity(0.9))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        }
                        .padding(.top, 60)
                        .padding(.leading, 16)
                        
                        // Content overlay (logo, title, subtitle)
                        VStack(spacing: 8) {
                            // Premier Padel logo
                            Image(systemName: "sportscourt.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                            
                            Text("PREMIER")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .tracking(1.5)
                            
                            Text("PADEL")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .tracking(0.8)
                            
                            Spacer()
                                .frame(height: 14)
                            
                            // Title
                            Text(title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            // Subtitle
                            Text(subtitle)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 120)
                        .padding(.horizontal, 24)
                    }
                    .frame(height: 380)
                    
                    // Progress bar section
                    VStack(spacing: 6) {
                        HStack {
                            Text("12:00")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            Text("18:30")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 2.5)
                                
                                Rectangle()
                                    .fill(Color(red: 0.96, green: 0.08, blue: 0.42))
                                    .frame(width: geometry.size.width * 0.3, height: 2.5)
                            }
                        }
                        .frame(height: 2.5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Live button
                        Button(action: {}) {
                            HStack(spacing: 10) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 18, weight: .bold))
                                
                                Text("Live")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
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
                                    .frame(maxWidth: .infinity)
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
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color(hex: "2C2D36"))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Event details
                    VStack(alignment: .leading, spacing: 18) {
                        DetailRow(icon: "clock", text: "Today 12:00")
                        DetailRow(icon: "mic", text: "Engelsk")
                        DetailRow(icon: "mappin.circle", text: "NEWGIZA Sports Club")
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Padel: Premier Padel")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Available to: 29 October at 18:30")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                    
                    // Recommended section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Kommende innen Premier Padel")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        // Live card
                        ZStack(alignment: .topLeading) {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                            }
                            .frame(height: 180)
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
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
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
        title: "New Giza P2",
        subtitle: "Premier Padel | 1. runde",
        imageUrl: "https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=800"
    )
}

