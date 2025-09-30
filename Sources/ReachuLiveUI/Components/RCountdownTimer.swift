import SwiftUI
import ReachuCore
import ReachuDesignSystem
import Combine

/// Countdown timer component for creating urgency in campaigns and live shows
public struct RCountdownTimer: View {
    
    // MARK: - Configuration
    public struct Configuration {
        public let style: TimerStyle
        public let size: TimerSize
        public let showLabels: Bool
        public let urgencyThreshold: TimeInterval
        public let onExpired: (() -> Void)?
        
        public init(
            style: TimerStyle = .digital,
            size: TimerSize = .medium,
            showLabels: Bool = true,
            urgencyThreshold: TimeInterval = 300, // 5 minutes
            onExpired: (() -> Void)? = nil
        ) {
            self.style = style
            self.size = size
            self.showLabels = showLabels
            self.urgencyThreshold = urgencyThreshold
            self.onExpired = onExpired
        }
    }
    
    public enum TimerStyle {
        case digital       // 00:05:30
        case blocks        // [00] [05] [30]
        case circular      // Circular progress
        case minimal       // 5m 30s
        
        var backgroundColor: Color {
            switch self {
            case .digital: return .black
            case .blocks: return .red
            case .circular: return .clear
            case .minimal: return .clear
            }
        }
    }
    
    public enum TimerSize {
        case small
        case medium
        case large
        
        var fontSize: Font {
            switch self {
            case .small: return .system(size: 12, weight: .bold, design: .monospaced)
            case .medium: return .system(size: 16, weight: .bold, design: .monospaced)
            case .large: return .system(size: 20, weight: .bold, design: .monospaced)
            }
        }
        
        var labelFont: Font {
            switch self {
            case .small: return .system(size: 8, weight: .medium)
            case .medium: return .system(size: 10, weight: .medium)
            case .large: return .system(size: 12, weight: .medium)
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6)
            case .medium: return EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
            case .large: return EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            }
        }
    }
    
    public enum BadgePosition {
        case topLeft, topRight, bottomLeft, bottomRight, center
    }
    
    public enum AnimationType {
        case none
        case pulse
        case flash
        case shake
    }
    
    // MARK: - Properties
    private let endDate: Date
    private let configuration: Configuration
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var timeRemaining: TimeInterval = 0
    @State private var isExpired = false
    @State private var isAnimating = false
    @State private var timer: Timer?
    
    // Colors based on theme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    // MARK: - Initializer
    public init(
        endDate: Date,
        configuration: Configuration = Configuration()
    ) {
        self.endDate = endDate
        self.configuration = configuration
    }
    
    // Convenience initializers
    public init(
        duration: TimeInterval,
        style: TimerStyle = .digital,
        size: TimerSize = .medium,
        onExpired: (() -> Void)? = nil
    ) {
        self.init(
            endDate: Date().addingTimeInterval(duration),
            configuration: Configuration(
                style: style,
                size: size,
                onExpired: onExpired
            )
        )
    }
    
    // MARK: - Body
    public var body: some View {
        if !isExpired {
            timerContent
                .onAppear {
                    startTimer()
                    startAnimation()
                }
                .onDisappear {
                    stopTimer()
                }
        } else {
            expiredContent
        }
    }
    
    // MARK: - Timer Content
    
    @ViewBuilder
    private var timerContent: some View {
        switch configuration.style {
        case .digital:
            digitalTimerView
        case .blocks:
            blocksTimerView
        case .circular:
            circularTimerView
        case .minimal:
            minimalTimerView
        }
    }
    
    // MARK: - Timer Styles
    
    private var digitalTimerView: some View {
        HStack(spacing: 2) {
            Text(formattedTime)
                .font(configuration.size.fontSize)
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding(configuration.size.padding)
        .background(
            RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                .fill(Color.black.opacity(0.8))
        )
        .scaleEffect(animationScale)
        .animation(pulseAnimation, value: isAnimating)
    }
    
    private var blocksTimerView: some View {
        HStack(spacing: ReachuSpacing.xs) {
            timeBlock(timeComponents.hours, label: "H")
            timeBlock(timeComponents.minutes, label: "M")
            timeBlock(timeComponents.seconds, label: "S")
        }
        .scaleEffect(animationScale)
        .animation(pulseAnimation, value: isAnimating)
    }
    
    private var circularTimerView: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(adaptiveColors.border, lineWidth: 3)
                .frame(width: circularSize, height: circularSize)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    isUrgent ? Color.red : adaptiveColors.primary,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: circularSize, height: circularSize)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            
            // Time text
            VStack(spacing: 2) {
                Text(shortFormattedTime)
                    .font(configuration.size.fontSize)
                    .foregroundColor(adaptiveColors.textPrimary)
                    .monospacedDigit()
                
                if configuration.showLabels {
                    Text("remaining")
                        .font(configuration.size.labelFont)
                        .foregroundColor(adaptiveColors.textSecondary)
                }
            }
        }
        .scaleEffect(animationScale)
        .animation(pulseAnimation, value: isAnimating)
    }
    
    private var minimalTimerView: some View {
        Text(minimalFormattedTime)
            .font(configuration.size.fontSize)
            .foregroundColor(isUrgent ? .red : adaptiveColors.textPrimary)
            .scaleEffect(animationScale)
            .animation(pulseAnimation, value: isAnimating)
    }
    
    // MARK: - Helper Views
    
    private func timeBlock(_ value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value))
                .font(configuration.size.fontSize)
                .foregroundColor(.white)
                .monospacedDigit()
            
            if configuration.showLabels {
                Text(label)
                    .font(configuration.size.labelFont)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(configuration.size.padding)
        .background(
            RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                .fill(isUrgent ? Color.red : Color.red.opacity(0.8))
        )
    }
    
    private var expiredContent: some View {
        HStack(spacing: ReachuSpacing.xs) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.red)
            
            Text("Offer Expired")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.red)
        }
        .padding(.horizontal, ReachuSpacing.sm)
        .padding(.vertical, ReachuSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Computed Properties
    
    private var timeComponents: (hours: Int, minutes: Int, seconds: Int) {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60
        return (hours, minutes, seconds)
    }
    
    private var formattedTime: String {
        let components = timeComponents
        if components.hours > 0 {
            return String(format: "%02d:%02d:%02d", components.hours, components.minutes, components.seconds)
        } else {
            return String(format: "%02d:%02d", components.minutes, components.seconds)
        }
    }
    
    private var shortFormattedTime: String {
        let components = timeComponents
        if components.hours > 0 {
            return String(format: "%dh %dm", components.hours, components.minutes)
        } else {
            return String(format: "%dm %ds", components.minutes, components.seconds)
        }
    }
    
    private var minimalFormattedTime: String {
        let components = timeComponents
        if components.hours > 0 {
            return "\(components.hours)h \(components.minutes)m"
        } else if components.minutes > 0 {
            return "\(components.minutes)m \(components.seconds)s"
        } else {
            return "\(components.seconds)s"
        }
    }
    
    private var isUrgent: Bool {
        timeRemaining <= configuration.urgencyThreshold
    }
    
    private var progress: CGFloat {
        let totalDuration = endDate.timeIntervalSince(Date().addingTimeInterval(-timeRemaining))
        return CGFloat(1.0 - (timeRemaining / totalDuration))
    }
    
    private var circularSize: CGFloat {
        switch configuration.size {
        case .small: return 60
        case .medium: return 80
        case .large: return 100
        }
    }
    
    private var animationScale: CGFloat {
        switch configuration.style {
        case .digital, .blocks, .circular:
            return isAnimating && isUrgent ? 1.05 : 1.0
        case .minimal:
            return isAnimating && isUrgent ? 1.1 : 1.0
        }
    }
    
    private var pulseAnimation: Animation? {
        guard isUrgent else { return nil }
        
        switch configuration.style {
        case .digital, .blocks:
            return .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
        case .circular:
            return .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
        case .minimal:
            return .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
        }
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        updateTimeRemaining()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTimeRemaining()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimeRemaining() {
        let remaining = endDate.timeIntervalSinceNow
        
        if remaining <= 0 {
            timeRemaining = 0
            isExpired = true
            stopTimer()
            configuration.onExpired?()
        } else {
            timeRemaining = remaining
        }
    }
    
    private func startAnimation() {
        isAnimating = true
    }
}

// MARK: - Preview

#Preview("Countdown Timer - Styles") {
    VStack(spacing: ReachuSpacing.xl) {
        RCountdownTimer(
            duration: 3661, // 1h 1m 1s
            style: .digital,
            size: .medium
        )
        
        RCountdownTimer(
            duration: 3661,
            style: .blocks,
            size: .medium
        )
        
        RCountdownTimer(
            duration: 3661,
            style: .circular,
            size: .large
        )
        
        RCountdownTimer(
            duration: 61, // 1m 1s (urgent)
            style: .minimal,
            size: .medium
        )
    }
    .padding()
}

#Preview("Countdown Timer - Sizes") {
    VStack(spacing: ReachuSpacing.lg) {
        HStack(spacing: ReachuSpacing.xl) {
            RCountdownTimer(duration: 1800, style: .digital, size: .small)
            RCountdownTimer(duration: 1800, style: .digital, size: .medium)
            RCountdownTimer(duration: 1800, style: .digital, size: .large)
        }
        
        Text("Different sizes comparison")
            .font(.caption)
            .foregroundColor(.gray)
    }
    .padding()
}
