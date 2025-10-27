//
//  SportView.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI

struct SportView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentCarouselIndex = 0
    
    let carouselCards = [
        CarouselCardData(
            imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600",
            time: "THIS EVENING 20:55",
            logo: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=100",
            title: "Port Vale - Stockport",
            subtitle: "League One | 14. runde"
        ),
        CarouselCardData(
            imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600",
            time: "TONIGHT 21:30",
            logo: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=100",
            title: "Manchester United - Chelsea",
            subtitle: "Premier League | 12. runde"
        ),
        CarouselCardData(
            imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600",
            time: "TOMORROW 19:00",
            logo: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=100",
            title: "Liverpool - Arsenal",
            subtitle: "Premier League | 12. runde"
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background
                Color(hex: "1B1B25")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with back button
                        HStack {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 50)
                        .padding(.bottom, 16)
                        
                        // Vis sendeskjema button
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16))
                                Text("Vis sendeskjema")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(hex: "302F3F"))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                        
                        // Vår beste sport Section with Carousel
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Vår beste sport")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                            
                            TabView(selection: $currentCarouselIndex) {
                                ForEach(carouselCards.indices, id: \.self) { index in
                                    CarouselCard(data: carouselCards[index])
                                        .padding(.horizontal, 24)
                                        .tag(index)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .frame(height: 440)
                        }
                        
                        // Live akkurat nå Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Live akkurat nå")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                            
                            LiveSportCard(
                                imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=300",
                                title: "New Giza P2",
                                subtitle: "Premier Padel",
                                time: "12:00"
                            )
                            .padding(.horizontal, 24)
                        }
                        
                        // Det beste fra Premier League Section
                        SportSection(
                            title: "Det beste fra Premier League",
                            cards: [
                                SportCard(
                                    imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=300",
                                    time: "00:51",
                                    title: "Haaland ofret sitt for å redde City-poeng",
                                    subtitle: "PREMIER LEAGUE | 2K. OKTOBER",
                                    isLarge: false
                                ),
                                SportCard(
                                    imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=300",
                                    time: "00:53",
                                    title: "Jørgen Strand Larsen scoring i Premier League",
                                    subtitle: "PREMIER LEAGUE",
                                    isLarge: false
                                )
                            ]
                        )
                        
                        // De beste motorklippene Section
                        SportSection(
                            title: "De beste motorklippene! 🏁",
                            cards: [
                                SportCard(
                                    imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=300",
                                    time: "29:26",
                                    title: "Dette er sikkeleg racing! Se høydepunktene fra Mexico Grand Prix",
                                    subtitle: "FORMEL 1 | 2K. OKTOBER",
                                    isLarge: false
                                ),
                                SportCard(
                                    imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=300",
                                    time: "00:51",
                                    title: "Haaland ofret sitt",
                                    subtitle: "PREMIER LEAGUE",
                                    isLarge: false
                                )
                            ]
                        )
                        
                        // Populær sport Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Populær sport")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.top, 32)
                            
                            HStack(spacing: 12) {
                                PopularSportCard(
                                    color: Color(hex: "4A148C"),
                                    icon: "soccerball",
                                    title: "Premier League"
                                )
                                
                                PopularSportCard(
                                    color: Color(hex: "00796B"),
                                    icon: "trophy.fill",
                                    title: "Carabao Cup"
                                )
                                
                                PopularSportCard(
                                    color: Color(hex: "E65100"),
                                    icon: "flag.fill",
                                    title: "Europa League"
                                )
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        .padding(.bottom, 100)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        .navigationBarHidden(true)
    }
}

struct CarouselCardData {
    let imageUrl: String
    let time: String
    let logo: String
    let title: String
    let subtitle: String
}

struct CarouselCard: View {
    let data: CarouselCardData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // Background image
                AsyncImage(url: URL(string: data.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                }
                .frame(height: 320)
                .clipped()
                .cornerRadius(16, corners: [.topLeft, .topRight])
                
                // Time badge
                Text(data.time)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .cornerRadius(6)
                    .padding(14)
            }
            
            // Bottom info section with dark background
            HStack(spacing: 12) {
                // Logo
                AsyncImage(url: URL(string: data.logo)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 54, height: 54)
                .background(Color.white)
                .cornerRadius(8)
                
                // Text info
                VStack(alignment: .leading, spacing: 5) {
                    Text(data.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(data.subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Three dots menu
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(90))
                        .padding(.trailing, 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(hex: "2C2D36"))
            .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
        }
        .background(Color(hex: "2C2D36"))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}

// Extension for corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct SportSection: View {
    let title: String
    let cards: [SportCard]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.top, 32)
            
            if cards.count == 1 && cards[0].isLarge {
                // Large single card
                cards[0]
                    .padding(.horizontal, 16)
            } else {
                // Horizontal scroll for multiple cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(cards.indices, id: \.self) { index in
                            cards[index]
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

struct SportCard: View {
    let imageUrl: String
    let time: String
    let title: String
    let subtitle: String
    let isLarge: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // Image
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                }
                .frame(width: isLarge ? nil : 240, height: isLarge ? 200 : 135)
                .clipped()
                .cornerRadius(12)
                
                // Time badge
                Text(time)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
                    .padding(8)
                
                // Crown icon centered
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Info section
            VStack(alignment: .leading, spacing: 4) {
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .textCase(.uppercase)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            .padding(.top, 8)
        }
        .frame(width: isLarge ? nil : 240)
    }
}

struct LiveSportCard: View {
    let imageUrl: String
    let title: String
    let subtitle: String
    let time: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image section with LIVE badge and crown
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                }
                .frame(height: 220)
                .clipped()
                .cornerRadius(16, corners: [.topLeft, .topRight])
                
                // LIVE badge
                Text("LIVE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.96, green: 0.08, blue: 0.42))
                    .cornerRadius(5)
                    .padding(14)
                
                // Crown icon centered
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 220)
            
            // Info section
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                    
                    // Progress bar
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(red: 0.96, green: 0.08, blue: 0.42))
                            .frame(width: 70, height: 3)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 3)
                    }
                    .frame(height: 3)
                    .padding(.top, 6)
                    
                    Text(time)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(red: 0.96, green: 0.08, blue: 0.42))
                        .padding(.top, 4)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(90))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(hex: "2C2D36"))
            .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
        }
        .background(Color(hex: "2C2D36"))
        .cornerRadius(16)
    }
}

struct PopularSportCard: View {
    let color: Color
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(color)
        .cornerRadius(12)
    }
}

#Preview {
    SportView()
}

