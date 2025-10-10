//
//  KlarnaPaymentDemoView.swift
//  ReachuDemoApp
//
//  Created by AI Assistant
//

import SwiftUI
import ReachuUI
import ReachuCore
import ReachuDesignSystem

#if os(iOS) && canImport(KlarnaMobileSDK)

struct KlarnaPaymentDemoView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: ReachuSpacing.xl) {
                // Header
                VStack(spacing: ReachuSpacing.md) {
                    Text("Klarna Payment Integration")
                        .font(ReachuTypography.largeTitle)
                        .foregroundColor(adaptiveColors.primary)
                    
                    Text("Test Klarna payment flow with real API")
                        .font(ReachuTypography.body)
                        .foregroundColor(adaptiveColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, ReachuSpacing.xl)
                
                // Info Card
                VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(adaptiveColors.primary)
                        Text("About this demo")
                            .font(ReachuTypography.headline)
                            .foregroundColor(adaptiveColors.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                        BulletPoint(text: "Uses Klarna Production API")
                        BulletPoint(text: "Creates real payment session")
                        BulletPoint(text: "Native Klarna payment view")
                        BulletPoint(text: "Complete authorization flow")
                    }
                }
                .padding(ReachuSpacing.lg)
                .background(adaptiveColors.surface)
                .cornerRadius(ReachuBorderRadius.large)
                .shadow(color: adaptiveColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Klarna Test View Component
                KlarnaTestView()
                    .padding(.top, ReachuSpacing.md)
            }
            .padding(.horizontal, ReachuSpacing.lg)
            .padding(.bottom, ReachuSpacing.xl)
        }
        .navigationTitle("Klarna Payment")
        .navigationBarTitleDisplayMode(.inline)
        .background(adaptiveColors.background)
    }
}

struct BulletPoint: View {
    let text: String
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: ReachuSpacing.sm) {
            Text("•")
                .font(ReachuTypography.body)
                .foregroundColor(adaptiveColors.primary)
            Text(text)
                .font(ReachuTypography.body)
                .foregroundColor(adaptiveColors.textSecondary)
        }
    }
}

#Preview {
    NavigationView {
        KlarnaPaymentDemoView()
    }
}

#else

// Fallback cuando Klarna SDK no está disponible
struct KlarnaPaymentDemoView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    var body: some View {
        VStack(spacing: ReachuSpacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(adaptiveColors.textSecondary)
            
            Text("Klarna SDK Not Available")
                .font(ReachuTypography.headline)
                .foregroundColor(adaptiveColors.textPrimary)
            
            Text("Klarna Mobile SDK is only available on iOS")
                .font(ReachuTypography.body)
                .foregroundColor(adaptiveColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(ReachuSpacing.xl)
        .navigationTitle("Klarna Payment")
        .navigationBarTitleDisplayMode(.inline)
        .background(adaptiveColors.background)
    }
}

#endif

