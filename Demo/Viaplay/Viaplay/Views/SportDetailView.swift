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
            // Background with blurred image
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 20)
            } placeholder: {
                Color.black
            }
            .ignoresSafeArea()
            
            // Dark overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header with back button
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    // Main content
                    VStack(spacing: 24) {
                        // Video/Image section
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                        }
                        .frame(height: 240)
                        .clipped()
                        .cornerRadius(0)
                        .padding(.top, 20)
                        
                        // Logo and Title
                        VStack(spacing: 16) {
                            Image(systemName: "sportscourt.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text(title)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(subtitle)
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                        
                        // Progress bar
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("12:00")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("18:30")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(height: 4)
                                    
                                    Rectangle()
                                        .fill(Color(red: 0.96, green: 0.08, blue: 0.42))
                                        .frame(width: geometry.size.width * 0.3, height: 4)
                                }
                            }
                            .frame(height: 4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            // Live button
                            Button(action: {}) {
                                HStack(spacing: 10) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 18, weight: .bold))
                                    
                                    Text("Live")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color(red: 0.96, green: 0.08, blue: 0.42))
                                .cornerRadius(12)
                            }
                            
                            HStack(spacing: 12) {
                                // Previous button
                                Button(action: {}) {
                                    Image(systemName: "backward.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(Color(hex: "2C2D36"))
                                        .cornerRadius(12)
                                }
                                
                                // Share button
                                Button(action: {}) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 16, weight: .semibold))
                                        
                                        Text("Share")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "2C2D36"))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Event details
                        VStack(alignment: .leading, spacing: 20) {
                            DetailRow(icon: "clock", text: "Today 12:00")
                            DetailRow(icon: "mic", text: "Engelsk")
                            DetailRow(icon: "mappin.circle", text: "NEWGIZA Sports Club")
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Padel: Premier Padel")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text("Available to: 29 October at 18:30")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // Recommended section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Kommende innen Premier Padel")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                            
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
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(12)
                                
                                Text("LIVE")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(red: 0.96, green: 0.08, blue: 0.42))
                                    .cornerRadius(5)
                                    .padding(12)
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 40)
                    }
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 17, weight: .regular))
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

