//
//  PowerContestCardWrapper.swift
//  Viaplay
//
//  Wrapper component that uses REngagementContestCard from SDK
//  Converts PowerContestEvent to SDK component format
//

import SwiftUI
import ReachuCore
import ReachuEngagementUI
import ReachuDesignSystem

struct PowerContestCardWrapper: View {
    let contest: PowerContestEvent
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
            PowerContestModal(contest: contest) {
                showModal = false
            }
        }
    }
}
