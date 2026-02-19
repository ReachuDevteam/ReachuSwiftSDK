//
//  CastingContestCardWrapper.swift
//  Viaplay
//
//  Wrapper component that uses REngagementContestCard from SDK
//  Converts CastingContestEvent to SDK component format
//

import SwiftUI
import ReachuCore
import ReachuEngagementUI
import ReachuDesignSystem

struct CastingContestCardWrapper: View {
    let contest: CastingContestEvent
    let onParticipate: () -> Void
    
    @State private var showModal = false
    
    var body: some View {
        let brandConfig = ReachuConfiguration.shared.brandConfiguration
        
        return REngagementContestCard(
            title: contest.title,
            description: contest.description,
            prize: contest.prize,
            contestType: contest.contestType == .quiz ? "Quiz" : "Konkurranse",
            imageAsset: contest.metadata?["imageAsset"],
            brandName: brandConfig.name,
            brandIcon: brandConfig.iconAsset,
            displayTime: contest.displayTime,
            onParticipate: {
                showModal = true
                onParticipate()
            }
        )
        .sheet(isPresented: $showModal) {
            CastingContestModal(contest: contest) {
                showModal = false
            }
        }
    }
}
