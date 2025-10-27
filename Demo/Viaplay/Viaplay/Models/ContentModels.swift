//
//  ContentModels.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import Foundation

struct HeroContent {
    let id = UUID()
    let title: String
    let description: String
    let imageUrl: String
    let hasCrown: Bool
}

struct ContinueWatchingItem: Identifiable {
    let id = UUID()
    let title: String
    let imageUrl: String
    let rentLabel: String?
    let progress: Double
}

// MARK: - Mock Data
extension HeroContent {
    static let mock: HeroContent = HeroContent(
        title: "un Forever",
        description: "yrke og overlev jakten. Med Oscar-vinner J.K. Simmons.",
        imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800",
        hasCrown: false
    )
}

extension ContinueWatchingItem {
    static let mockItems: [ContinueWatchingItem] = [
        ContinueWatchingItem(
            title: "Hotell Transylvania: Monsterferie",
            imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=300",
            rentLabel: nil,
            progress: 0.0
        ),
        ContinueWatchingItem(
            title: "The Boss Baby",
            imageUrl: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=300",
            rentLabel: nil,
            progress: 0.0
        )
    ]
}
