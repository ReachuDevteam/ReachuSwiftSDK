//
//  LiveMatchViewRefactored.swift
//  Viaplay
//
//  Refactored LiveMatchView using small, reusable components
//  Reduced from 1408 lines to ~100 lines
//

import SwiftUI

struct LiveMatchViewRefactored: View {
    let match: Match
    let onDismiss: () -> Void
    
    @StateObject private var viewModel: LiveMatchViewModel
    
    init(match: Match, onDismiss: @escaping () -> Void) {
        self.match = match
        self.onDismiss = onDismiss
        self._viewModel = StateObject(wrappedValue: LiveMatchViewModel(match: match))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(hex: "1B1B25").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with teams and score
                    MatchHeaderView(
                        match: match,
                        homeScore: viewModel.matchSimulation.homeScore,
                        awayScore: viewModel.matchSimulation.awayScore,
                        currentMinute: viewModel.matchSimulation.currentMinute,
                        onDismiss: onDismiss
                    )
                    .padding(.top, 8)
                    
                    // Sponsor banner
                    SponsorBanner()
                    
                    // Navigation tabs
                    MatchNavigationTabs(selectedTab: $viewModel.selectedTab)
                    
                    // Content area (changes based on selected tab)
                    MatchContentView(
                        selectedTab: viewModel.selectedTab,
                        viewModel: viewModel
                    )
                    .frame(maxHeight: .infinity)
                    
                    // Video controls and timeline
                    VideoTimelineControl(
                        currentMinute: viewModel.matchSimulation.currentMinute,
                        selectedMinute: $viewModel.selectedMinute,
                        events: viewModel.matchSimulation.events,
                        isPlaying: viewModel.playerViewModel.isPlaying,
                        isMuted: viewModel.playerViewModel.isMuted,
                        onPlayPause: viewModel.playerViewModel.togglePlayPause,
                        onToggleMute: viewModel.playerViewModel.toggleMute,
                        onSeek: { minute in
                            viewModel.jumpToMinute(minute)
                        }
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}

#Preview {
    LiveMatchViewRefactored(match: Match.barcelonaPSG) {
        print("Dismissed")
    }
    .preferredColorScheme(.dark)
}


