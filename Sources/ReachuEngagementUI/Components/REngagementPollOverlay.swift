//
//  REngagementPollOverlay.swift
//  ReachuEngagementUI
//
//  Poll overlay component for engagement system
//  Uses SDK colors from configuration instead of hardcoded values
//

import SwiftUI
import ReachuCore
import ReachuDesignSystem

/// Poll option data for overlay
public struct REngagementPollOverlayOption: Identifiable {
    public let id: String
    public let text: String
    public let avatarUrl: String?
    
    public init(id: String = UUID().uuidString, text: String, avatarUrl: String? = nil) {
        self.id = id
        self.text = text
        self.avatarUrl = avatarUrl
    }
}

/// Poll overlay component for engagement system
public struct REngagementPollOverlay: View {
    let question: String
    let subtitle: String?
    let options: [REngagementPollOverlayOption]
    let duration: Int
    let isChatExpanded: Bool
    let onVote: (String) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedOption: String?
    @State private var hasVoted = false
    @State private var showResults = false
    @State private var dragOffset: CGFloat = 0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    private var bottomPadding: CGFloat {
        if isLandscape {
            return isChatExpanded ? 250 : 156
        } else {
            return isChatExpanded ? 250 : 80
        }
    }
    
    public init(
        question: String,
        subtitle: String? = nil,
        options: [REngagementPollOverlayOption],
        duration: Int,
        isChatExpanded: Bool,
        onVote: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.question = question
        self.subtitle = subtitle
        self.options = options
        self.duration = duration
        self.isChatExpanded = isChatExpanded
        self.onVote = onVote
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        let colors = ReachuColors.adaptive(for: colorScheme)
        
        VStack(spacing: 0) {
            if isLandscape {
                Spacer()
                HStack(spacing: 0) {
                    Spacer()
                    pollCard(colors: colors)
                        .frame(width: 300)
                        .padding(.trailing, ReachuSpacing.md)
                        .padding(.bottom, ReachuSpacing.md)
                        .offset(x: dragOffset)
                        .gesture(dragGesture)
                }
            } else {
                Spacer()
                pollCard(colors: colors)
                    .padding(.horizontal, ReachuSpacing.md)
                    .padding(.bottom, bottomPadding)
                    .offset(y: dragOffset)
                    .gesture(dragGesture)
            }
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if isLandscape {
                    if value.translation.width > 0 {
                        dragOffset = value.translation.width
                    }
                } else {
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                if isLandscape {
                    if value.translation.width > threshold {
                        onDismiss()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                } else {
                    if value.translation.height > threshold {
                        onDismiss()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
            }
    }
    
    private func pollCard(colors: AdaptiveColors) -> some View {
        ZStack {
            if !showResults {
                pollFrontView(colors: colors)
                    .rotation3DEffect(.degrees(0), axis: (x: 0, y: 1, z: 0))
            }
            
            if showResults {
                pollResultsView(colors: colors)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .rotation3DEffect(
            .degrees(showResults ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
    }
    
    private func pollFrontView(colors: AdaptiveColors) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: isLandscape ? ReachuSpacing.md : ReachuSpacing.sm) {
                REngagementDragIndicator()
                    .padding(.top, ReachuSpacing.xs)
                
                HStack {
                    REngagementSponsorBadge()
                    Spacer()
                }
                .padding(.horizontal, ReachuSpacing.sm)
                .padding(.top, 4)
                
                Text(question)
                    .font(.system(size: isLandscape ? 16 : 14, weight: .bold))
                    .foregroundColor(colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, ReachuSpacing.md)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: isLandscape ? 12 : 10, weight: .regular))
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .padding(.horizontal, ReachuSpacing.md)
                }
                
                VStack(spacing: isLandscape ? ReachuSpacing.xs : 6) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                        pollOptionButton(option: option, index: index, colors: colors)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: isLandscape ? 10 : 9))
                    Text("\(duration)s")
                        .font(.system(size: isLandscape ? 11 : 10))
                }
                .foregroundColor(colors.textSecondary)
                .padding(.top, 4)
            }
            .padding(isLandscape ? ReachuSpacing.md : ReachuSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                    .fill(colors.surface.opacity(0.4))
                    .background(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                            .fill(.ultraThinMaterial)
                    )
            )
            .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 8)
        }
    }
    
    private func pollResultsView(colors: AdaptiveColors) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: isLandscape ? ReachuSpacing.md : ReachuSpacing.sm) {
                REngagementDragIndicator()
                    .padding(.top, ReachuSpacing.xs)
                
                Text("Resultater")
                    .font(.system(size: isLandscape ? 18 : 14, weight: .bold))
                    .foregroundColor(colors.textPrimary)
                    .padding(.horizontal, ReachuSpacing.md)
                
                Text("Takk for at du stemte!")
                    .font(.system(size: isLandscape ? 13 : 10, weight: .regular))
                    .foregroundColor(colors.primary)
                    .padding(.horizontal, ReachuSpacing.md)
                
                VStack(spacing: isLandscape ? ReachuSpacing.md : ReachuSpacing.xs) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                        resultBar(option: option, isSelected: option.id == selectedOption, colors: colors)
                    }
                }
                .padding(.top, isLandscape ? ReachuSpacing.md : ReachuSpacing.xs)
            }
            .padding(isLandscape ? 20 : ReachuSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                    .fill(colors.surface.opacity(0.4))
                    .background(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                            .fill(.ultraThinMaterial)
                    )
            )
            .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 8)
        }
    }
    
    private func resultBar(option: REngagementPollOverlayOption, isSelected: Bool, colors: AdaptiveColors) -> some View {
        let percentage = calculatePercentage(for: option)
        
        return VStack(alignment: .leading, spacing: isLandscape ? 6 : 4) {
            HStack {
                Text(option.text)
                    .font(.system(size: isLandscape ? 15 : 12, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                
                Spacer()
                
                Text("\(Int(percentage))%")
                    .font(.system(size: isLandscape ? 15 : 12, weight: .bold))
                    .foregroundColor(isSelected ? colors.primary : colors.textPrimary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: isLandscape ? 10 : ReachuBorderRadius.small)
                        .fill(colors.textPrimary.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: isLandscape ? 10 : ReachuBorderRadius.small)
                        .fill(isSelected ? colors.primary : colors.primary.opacity(0.6))
                        .frame(width: geometry.size.width * (percentage / 100))
                }
            }
            .frame(height: isLandscape ? 12 : 6)
        }
        .padding(.horizontal, ReachuSpacing.md)
    }
    
    private func calculatePercentage(for option: REngagementPollOverlayOption) -> Double {
        guard let selected = selectedOption else { return 0 }
        
        if option.id == selected {
            return 75.0
        } else {
            let remaining = 25.0
            let otherOptions = options.filter { $0.id != selected }.count
            return remaining / Double(otherOptions)
        }
    }
    
    private func pollOptionButton(option: REngagementPollOverlayOption, index: Int, colors: AdaptiveColors) -> some View {
        Button(action: {
            guard !hasVoted else { return }
            selectedOption = option.id
            hasVoted = true
            onVote(option.text)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    showResults = true
                }
            }
        }) {
            HStack(spacing: 10) {
                if let avatarUrl = option.avatarUrl, !avatarUrl.isEmpty, let url = URL(string: avatarUrl) {
                    CachedAsyncImage(url: url) { image in
                        Circle()
                            .fill(colors.surface)
                            .frame(width: isLandscape ? 40 : 36, height: isLandscape ? 40 : 36)
                            .overlay(
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: isLandscape ? 30 : 26, height: isLandscape ? 30 : 26)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    } placeholder: {
                        Circle()
                            .fill(colors.surfaceSecondary)
                            .frame(width: isLandscape ? 40 : 36, height: isLandscape ? 40 : 36)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .tint(colors.textPrimary)
                            )
                    }
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [colors.primary.opacity(0.6), colors.primary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: isLandscape ? 40 : 36, height: isLandscape ? 40 : 36)
                        .overlay(
                            Text(String(option.text.prefix(1)).uppercased())
                                .font(.system(size: isLandscape ? 16 : 14, weight: .bold))
                                .foregroundColor(colors.textOnPrimary)
                        )
                }
                
                Text(option.text)
                    .font(.system(size: isLandscape ? 14 : 12, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, ReachuSpacing.sm)
            .padding(.vertical, ReachuSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: isLandscape ? 20 : ReachuBorderRadius.large)
                    .fill(
                        selectedOption == option.id
                        ? colors.primary.opacity(0.6)
                        : colors.surfaceSecondary
                    )
            )
        }
        .disabled(hasVoted)
    }
}
