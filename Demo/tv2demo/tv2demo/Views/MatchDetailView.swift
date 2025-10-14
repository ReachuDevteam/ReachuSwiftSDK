import SwiftUI
import ReachuUI

struct MatchDetailView: View {
    let match: Match
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cartManager: CartManager
    @StateObject private var castingManager = CastingManager.shared
    @State private var showVideoPlayer = false
    @State private var showCastDeviceSelection = false
    @State private var showCastingView = false
    
    var body: some View {
        ZStack {
            // Background
            TV2Theme.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Image with gradient overlay
                    ZStack(alignment: .topLeading) {
                        // Background image
                        Image(match.backgroundImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: 400)
                            .clipped()
                            .blur(radius: 0.5) // Slight blur for better text readability
                        
                        // Multi-layered gradient overlay for depth
                        ZStack {
                            // Vertical gradient (top to bottom)
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.black.opacity(0.4),
                                    Color.black.opacity(0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            
                            // Horizontal gradient from sides
                            HStack(spacing: 0) {
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.6),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: 60)
                                
                                Spacer()
                                
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color.black.opacity(0.6)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: 60)
                            }
                        }
                        .frame(height: 400)
                        
                        // Top bar buttons
                        VStack(alignment: .leading, spacing: TV2Theme.Spacing.sm) {
                            HStack {
                                Button(action: { dismiss() }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                
                                Spacer()
                                
                                HStack(spacing: TV2Theme.Spacing.md) {
                                    Button(action: {}) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                    }
                                    
                                    // Cast button - ACTIVADO
                                    Button(action: { showCastDeviceSelection = true }) {
                                        Image(systemName: castingManager.isCasting ? "tv.fill" : "airplayvideo")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(castingManager.isCasting ? TV2Theme.Colors.primary : .white)
                                            .frame(width: 44, height: 44)
                                    }
                                    
                                    Circle()
                                        .fill(TV2Theme.Colors.secondary)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text("A")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, TV2Theme.Spacing.md)
                        .padding(.top, 50)
                    }
                    
                    // Content section
                    VStack(alignment: .leading, spacing: TV2Theme.Spacing.lg) {
                        // Title
                        VStack(alignment: .leading, spacing: TV2Theme.Spacing.xs) {
                            Text(match.title)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(TV2Theme.Colors.textPrimary)
                            
                            Text(match.subtitle)
                                .font(TV2Theme.Typography.body)
                                .foregroundColor(TV2Theme.Colors.textSecondary)
                        }
                        .padding(.horizontal, TV2Theme.Spacing.md)
                        .padding(.top, TV2Theme.Spacing.lg)
                        
                        // Action Buttons
                        HStack(spacing: TV2Theme.Spacing.md) {
                            // Play button - Opens fullscreen video player
                            Button(action: { showVideoPlayer = true }) {
                                HStack(spacing: TV2Theme.Spacing.sm) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Spill av")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, TV2Theme.Spacing.md)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "#A891FF"))
                                )
                            }
                            
                            // Highlights button
                            Button(action: {}) {
                                HStack(spacing: TV2Theme.Spacing.sm) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Sammendrag")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, TV2Theme.Spacing.md)
                                .background(
                                    Capsule()
                                        .strokeBorder(.white, lineWidth: 2)
                                )
                            }
                        }
                        .padding(.horizontal, TV2Theme.Spacing.md)
                        
                        // Description
                        Text("Fra \(match.venue), Dortmund og kampen mellom \(match.homeTeam.name) og \(match.awayTeam.name) i \(match.competition).")
                            .font(TV2Theme.Typography.body)
                            .foregroundColor(TV2Theme.Colors.textPrimary)
                            .padding(.horizontal, TV2Theme.Spacing.md)
                        
                        if let commentator = match.commentator {
                            Text("Kommentator: \(commentator).")
                                .font(TV2Theme.Typography.body)
                                .foregroundColor(TV2Theme.Colors.textPrimary)
                                .padding(.horizontal, TV2Theme.Spacing.md)
                        }
                        
                        Divider()
                            .background(TV2Theme.Colors.surfaceLight)
                            .padding(.horizontal, TV2Theme.Spacing.md)
                            .padding(.vertical, TV2Theme.Spacing.sm)
                        
                        // Availability section
                        VStack(alignment: .leading, spacing: TV2Theme.Spacing.xs) {
                            Text(match.availability.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(TV2Theme.Colors.textPrimary)
                            
                            Text(match.availability.description)
                                .font(TV2Theme.Typography.body)
                                .foregroundColor(TV2Theme.Colors.textSecondary)
                        }
                        .padding(.horizontal, TV2Theme.Spacing.md)
                        
                        Divider()
                            .background(TV2Theme.Colors.surfaceLight)
                            .padding(.horizontal, TV2Theme.Spacing.md)
                            .padding(.vertical, TV2Theme.Spacing.sm)
                        
                        // Related teams section
                        VStack(alignment: .leading, spacing: TV2Theme.Spacing.md) {
                            Text("Følg lagene")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(TV2Theme.Colors.textPrimary)
                                .padding(.horizontal, TV2Theme.Spacing.md)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: TV2Theme.Spacing.md) {
                                    ForEach(match.relatedContent) { related in
                                        TeamCard(team: related.team)
                                    }
                                }
                                .padding(.horizontal, TV2Theme.Spacing.md)
                            }
                        }
                        
                        Divider()
                            .background(TV2Theme.Colors.surfaceLight)
                            .padding(.horizontal, TV2Theme.Spacing.md)
                            .padding(.vertical, TV2Theme.Spacing.sm)
                        
                        // Products carousel from SDK
                        RProductSlider(
                            title: "Produkter",
                            layout: .cards
                        )
                        
                        // All football live section
                        VStack(alignment: .leading, spacing: TV2Theme.Spacing.md) {
                            Text("All fotball direkte")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(TV2Theme.Colors.textPrimary)
                                .padding(.horizontal, TV2Theme.Spacing.md)
                            
                            // More content cards would go here
                            Text("Mer innhold kommer her...")
                                .font(TV2Theme.Typography.body)
                                .foregroundColor(TV2Theme.Colors.textSecondary)
                                .padding(.horizontal, TV2Theme.Spacing.md)
                                .padding(.bottom, 100)
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showVideoPlayer) {
            TV2VideoPlayer(match: match) {
                showVideoPlayer = false
            }
        }
        .sheet(isPresented: $showCastDeviceSelection) {
            CastDeviceSelectionView { device in
                castingManager.startCasting(to: device)
                showCastingView = true
            }
        }
        .fullScreenCover(isPresented: $showCastingView) {
            CastingActiveView(match: match)
                .environmentObject(cartManager)
        }
        .onChange(of: castingManager.isCasting) { isCasting in
            if !isCasting {
                showCastingView = false
            }
        }
    }
}

// MARK: - Team Card Component
struct TeamCard: View {
    let team: Team
    
    var body: some View {
        VStack(spacing: TV2Theme.Spacing.md) {
            // Team logo
            Circle()
                .fill(Color.white)
                .frame(width: 120, height: 120)
                .overlay(
                    Image(team.logo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                )
        }
        .frame(width: 160, height: 160)
        .background(TV2Theme.Colors.surface)
        .cornerRadius(TV2Theme.CornerRadius.medium)
    }
}

#Preview {
    MatchDetailView(match: Match.barcelonaPSG)
}

