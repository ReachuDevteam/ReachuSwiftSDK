//
//  REngagementContestCard.swift
//  ReachuEngagementUI
//
//  Contest card component for engagement system
//  Displays contest/competition information with prize details
//  Uses SDK colors from configuration instead of hardcoded values
//

import SwiftUI
import ReachuCore
import ReachuDesignSystem

#if canImport(UIKit)
import UIKit
#endif

/// Contest card component for engagement system
public struct REngagementContestCard: View {
    let title: String
    let description: String
    let prize: String
    let contestType: String?
    let imageAsset: String?
    let brandName: String?
    let brandIcon: String?
    let displayTime: String?
    let onParticipate: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(
        title: String,
        description: String,
        prize: String,
        contestType: String? = nil,
        imageAsset: String? = nil,
        brandName: String? = nil,
        brandIcon: String? = nil,
        displayTime: String? = nil,
        onParticipate: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.prize = prize
        self.contestType = contestType
        self.imageAsset = imageAsset
        self.brandName = brandName
        self.brandIcon = brandIcon
        self.displayTime = displayTime
        self.onParticipate = onParticipate
    }
    
    public var body: some View {
        let colors = ReachuColors.adaptive(for: colorScheme)
        
        VStack(alignment: .leading, spacing: 10) {
            // Header
            headerView(colors: colors)
            
            // Title and description
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .lineSpacing(1)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(colors.textSecondary)
                    .lineSpacing(1)
            }
            
            // Prize information
            Text(prize)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(colors.primary)
                .padding(.vertical, 4)
            
            // Contest image (if available)
            // Uses dynamic assets: elkjop_konk for full contest graphic, elkjop_gavekort for gift card only
            // Legacy Power assets (gavekortpower) are preserved in comments for reference
            if let imageAsset = imageAsset {
                // Map Power assets to Elkjøp assets
                let mappedAsset = mapAssetName(imageAsset)
                Image(mappedAsset)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(ReachuBorderRadius.small)
                    .padding(.vertical, ReachuSpacing.xs)
            }
            
            // Participate button
            Button(action: {
                onParticipate()
            }) {
                HStack {
                    Spacer()
                    Text("Delta")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(colors.textOnPrimary)
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                        .fill(
                            LinearGradient(
                                colors: [
                                    colors.primary,
                                    colors.primary.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
        }
        .padding(ReachuSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                .fill(colors.surfaceSecondary.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    colors.primary.opacity(0.4),
                                    colors.primary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Header View
    
    private func headerView(colors: AdaptiveColors) -> some View {
        // Get effective brand config (dynamic takes precedence)
        let effectiveBrand = ReachuConfiguration.shared.effectiveBrandConfiguration
        let displayBrandName = brandName ?? effectiveBrand.name
        let displayBrandIcon: String? = brandIcon ?? effectiveBrand.iconAsset
        
        return HStack(spacing: ReachuSpacing.xs) {
            // Brand icon - use dynamic config if available
            if let iconAsset = displayBrandIcon {
                Image(iconAsset)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            }
            
            HStack(spacing: ReachuSpacing.xs) {
                VStack(alignment: .leading, spacing: 2) {
                    if let brandName = brandName {
                        Text(brandName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(colors.textPrimary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 9))
                            .foregroundColor(colors.primary)
                        
                        if let contestType = contestType {
                            Text(contestType)
                                .font(.system(size: 10))
                                .foregroundColor(colors.textSecondary)
                        }
                        
                        if let displayTime = displayTime {
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(colors.textTertiary)
                            
                            Text(displayTime)
                                .font(.system(size: 10))
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                }
                
                // Badge alineado a la derecha del nombre
                if displayBrandName != nil {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundColor(colors.info)
                        .padding(.leading, 4)
                }
            }
            
            Spacer()
            
            // Campaign sponsor badge - alineado a la derecha
            // Use dynamic sponsor badge text if available
            HStack {
                Spacer()
                let sponsorText = getSponsorBadgeText()
                CampaignSponsorBadge(
                    text: sponsorText,
                    maxWidth: 80,
                    maxHeight: 24,
                    alignment: .trailing
                )
            }
        }
    }
    
    private func getSponsorBadgeText() -> String {
        // Try dynamic config first
        if let dynamicBrand = ReachuConfiguration.shared.dynamicBrandConfig,
           let sponsorTexts = dynamicBrand.sponsorBadgeText {
            let currentLanguage = ReachuLocalization.shared.language
            if let text = sponsorTexts[currentLanguage] {
                return text
            }
        }
        // Fallback to default
        return "Sponset av"
    }
    
    // MARK: - Asset Mapping
    
    /// Maps legacy Power assets to Elkjøp assets when brand is Elkjøp.
    /// For Power brand, uses gavekortpower and billeter_power2 directly.
    /// 
    /// Asset Reference:
    /// - Power: gavekortpower (full contest graphic with orange background, gift box, gift card)
    /// - Elkjøp: elkjop_konk (full contest graphic - equivalent to gavekortpower)
    /// - Elkjøp: elkjop_gavekort (gift card only asset)
    private func mapAssetName(_ assetName: String) -> String {
        let isPower = ReachuConfiguration.shared.effectiveBrandConfiguration.name.lowercased().contains("power")
        if isPower {
            // Power brand: use Power assets as-is (gavekortpower, billeter_power2, etc.)
            return assetName
        }
        switch assetName {
        case "gavekortpower":
            // Power asset - map to Elkjøp when brand is Elkjøp
            return "elkjop_konk"
        case "elkjop_gavekort":
            // Gift card only asset (for Elkjøp) - use when only showing the gift card
            return "elkjop_gavekort"
        case "elkjop_konk":
            // Full contest graphic asset (for Elkjøp) - use for complete contest visual
            // Equivalent to Power's gavekortpower asset
            return "elkjop_konk"
        case "competitio-skistar-1", "competitio-skistar-2":
            // Skistar demo assets - pass through
            return assetName
        default:
            // Return as-is for other assets
            return assetName
        }
    }
}
