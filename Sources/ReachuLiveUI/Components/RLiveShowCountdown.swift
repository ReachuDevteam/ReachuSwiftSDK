import SwiftUI
import ReachuCore
import ReachuLiveShow
import ReachuDesignSystem
import Foundation

/// Live show countdown component for showing when shows start
public struct RLiveShowCountdown: View {
    
    // MARK: - Configuration
    public struct Configuration {
        public let style: CountdownStyle
        public let size: CountdownSize
        public let showDate: Bool
        public let showTime: Bool
        public let showDaysWhenFar: Bool
        public let timeZone: TimeZone
        public let dateFormat: String
        public let onShowStarted: (() -> Void)?
        
        public init(
            style: CountdownStyle = .card,
            size: CountdownSize = .medium,
            showDate: Bool = true,
            showTime: Bool = true,
            showDaysWhenFar: Bool = true,
            timeZone: TimeZone = .current,
            dateFormat: String = "MMM dd, yyyy",
            onShowStarted: (() -> Void)? = nil
        ) {
            self.style = style
            self.size = size
            self.showDate = showDate
            self.showTime = showTime
            self.showDaysWhenFar = showDaysWhenFar
            self.timeZone = timeZone
            self.dateFormat = dateFormat
            self.onShowStarted = onShowStarted
        }
    }
    
    public enum CountdownStyle {
        case card           // Card with background
        case banner         // Banner style
        case minimal        // Text only
        case badge          // Small badge
        
        var hasBackground: Bool {
            switch self {
            case .card, .banner: return true
            case .minimal, .badge: return false
            }
        }
    }
    
    public enum CountdownSize {
        case small
        case medium
        case large
        
        var titleFont: Font {
            switch self {
            case .small: return .system(size: 12, weight: .semibold)
            case .medium: return .system(size: 16, weight: .semibold)
            case .large: return .system(size: 20, weight: .bold)
            }
        }
        
        var timeFont: Font {
            switch self {
            case .small: return .system(size: 14, weight: .bold, design: .monospaced)
            case .medium: return .system(size: 18, weight: .bold, design: .monospaced)
            case .large: return .system(size: 24, weight: .bold, design: .monospaced)
            }
        }
        
        var dateFont: Font {
            switch self {
            case .small: return .system(size: 10, weight: .medium)
            case .medium: return .system(size: 12, weight: .medium)
            case .large: return .system(size: 14, weight: .medium)
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            case .medium: return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
            case .large: return EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
            }
        }
    }
    
    // MARK: - Properties
    private let liveShow: LiveShowSchedule
    private let configuration: Configuration
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var timeRemaining: TimeInterval = 0
    @State private var isLive = false
    @State private var timer: Timer?
    
    // Colors based on theme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    // MARK: - Live Show Schedule Model
    public struct LiveShowSchedule {
        public let id: String
        public let title: String
        public let streamerName: String
        public let startDate: Date
        public let thumbnailUrl: String?
        public let description: String?
        
        public init(
            id: String,
            title: String,
            streamerName: String,
            startDate: Date,
            thumbnailUrl: String? = nil,
            description: String? = nil
        ) {
            self.id = id
            self.title = title
            self.streamerName = streamerName
            self.startDate = startDate
            self.thumbnailUrl = thumbnailUrl
            self.description = description
        }
    }
    
    // MARK: - Initializer
    public init(
        liveShow: LiveShowSchedule,
        configuration: Configuration = Configuration()
    ) {
        self.liveShow = liveShow
        self.configuration = configuration
    }
    
    // Convenience initializer
    public init(
        title: String,
        streamerName: String,
        startDate: Date,
        style: CountdownStyle = .card,
        onShowStarted: (() -> Void)? = nil
    ) {
        self.init(
            liveShow: LiveShowSchedule(
                id: UUID().uuidString,
                title: title,
                streamerName: streamerName,
                startDate: startDate
            ),
            configuration: Configuration(
                style: style,
                onShowStarted: onShowStarted
            )
        )
    }
    
    // MARK: - Body
    public var body: some View {
        Group {
            if isLive {
                liveNowContent
            } else {
                countdownContent
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Content Views
    
    @ViewBuilder
    private var countdownContent: some View {
        switch configuration.style {
        case .card:
            cardStyleContent
        case .banner:
            bannerStyleContent
        case .minimal:
            minimalStyleContent
        case .badge:
            badgeStyleContent
        }
    }
    
    private var cardStyleContent: some View {
        VStack(spacing: ReachuSpacing.sm) {
            // Header
            VStack(spacing: ReachuSpacing.xs) {
                HStack(spacing: ReachuSpacing.xs) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    
                    Text("LIVE SHOW")
                        .font(configuration.size.titleFont)
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
                
                Text(liveShow.title)
                    .font(configuration.size.titleFont)
                    .foregroundColor(adaptiveColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text("with \(liveShow.streamerName)")
                    .font(configuration.size.dateFont)
                    .foregroundColor(adaptiveColors.textSecondary)
            }
            
            // Countdown
            countdownDisplay
            
            // Date info
            if configuration.showDate || configuration.showTime {
                dateTimeDisplay
            }
        }
        .padding(configuration.size.padding)
        .background(adaptiveColors.surface)
        .cornerRadius(ReachuBorderRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                .stroke(adaptiveColors.border, lineWidth: 1)
        )
        .shadow(
            color: adaptiveColors.textPrimary.opacity(0.1),
            radius: 8,
            x: 0,
            y: 4
        )
    }
    
    private var bannerStyleContent: some View {
        HStack(spacing: ReachuSpacing.md) {
            // Live indicator
            VStack(spacing: ReachuSpacing.xs) {
                HStack(spacing: ReachuSpacing.xs) {
                    Circle()
                        .fill(.red)
                        .frame(width: 6, height: 6)
                    
                    Text("LIVE SHOW")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                }
                
                Text("STARTS IN")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(adaptiveColors.textSecondary)
            }
            
            // Countdown
            Text(formattedTimeRemaining)
                .font(configuration.size.timeFont)
                .foregroundColor(adaptiveColors.textPrimary)
                .monospacedDigit()
            
            Spacer()
            
            // Show info
            VStack(alignment: .trailing, spacing: 2) {
                Text(liveShow.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(adaptiveColors.textPrimary)
                    .lineLimit(1)
                
                if configuration.showDate {
                    Text(formattedDate)
                        .font(.system(size: 10))
                        .foregroundColor(adaptiveColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, ReachuSpacing.md)
        .padding(.vertical, ReachuSpacing.sm)
        .background(adaptiveColors.surface)
        .cornerRadius(ReachuBorderRadius.small)
        .overlay(
            RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                .stroke(adaptiveColors.border, lineWidth: 1)
        )
    }
    
    private var minimalStyleContent: some View {
        HStack(spacing: ReachuSpacing.sm) {
            Text("Live show starts in")
                .font(configuration.size.dateFont)
                .foregroundColor(adaptiveColors.textSecondary)
            
            Text(formattedTimeRemaining)
                .font(configuration.size.timeFont)
                .foregroundColor(adaptiveColors.primary)
                .monospacedDigit()
        }
    }
    
    private var badgeStyleContent: some View {
        Text(shortFormattedTime)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.red)
            .cornerRadius(ReachuBorderRadius.small)
    }
    
    private var liveNowContent: some View {
        HStack(spacing: ReachuSpacing.sm) {
            // Pulsing live indicator
            HStack(spacing: ReachuSpacing.xs) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                    .scaleEffect(timer != nil ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: timer != nil)
                
                Text("LIVE NOW")
                    .font(configuration.size.titleFont)
                    .foregroundColor(.red)
                    .fontWeight(.bold)
            }
            
            Text(liveShow.title)
                .font(configuration.size.titleFont)
                .foregroundColor(adaptiveColors.textPrimary)
        }
        .padding(configuration.size.padding)
        .background(
            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                .fill(adaptiveColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                        .stroke(.red.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .red.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Helper Views
    
    private var countdownDisplay: some View {
        VStack(spacing: ReachuSpacing.xs) {
            if daysRemaining > 0 && configuration.showDaysWhenFar {
                // Show days when far in future
                Text("\(daysRemaining) day\(daysRemaining == 1 ? "" : "s")")
                    .font(configuration.size.timeFont)
                    .foregroundColor(adaptiveColors.primary)
                    .fontWeight(.bold)
            } else {
                // Show hours:minutes:seconds
                Text(formattedTimeRemaining)
                    .font(configuration.size.timeFont)
                    .foregroundColor(isUrgent ? .red : adaptiveColors.primary)
                    .monospacedDigit()
                    .scaleEffect(isUrgent ? (timer != nil ? 1.05 : 1.0) : 1.0)
                    .animation(
                        isUrgent ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .none,
                        value: timer != nil
                    )
            }
            
            Text("until live show starts")
                .font(configuration.size.dateFont)
                .foregroundColor(adaptiveColors.textSecondary)
        }
    }
    
    private var dateTimeDisplay: some View {
        VStack(spacing: ReachuSpacing.xs) {
            if configuration.showDate {
                Text(formattedDate)
                    .font(configuration.size.dateFont)
                    .foregroundColor(adaptiveColors.textPrimary)
                    .fontWeight(.medium)
            }
            
            if configuration.showTime {
                Text(formattedTime)
                    .font(configuration.size.dateFont)
                    .foregroundColor(adaptiveColors.textSecondary)
            }
        }
        .padding(.top, ReachuSpacing.xs)
        .overlay(
            Rectangle()
                .fill(adaptiveColors.border)
                .frame(height: 1),
            alignment: .top
        )
    }
    
    // MARK: - Computed Properties
    
    private var daysRemaining: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: liveShow.startDate)
        return max(0, components.day ?? 0)
    }
    
    private var isUrgent: Bool {
        timeRemaining <= 3600 // 1 hour or less
    }
    
    private var formattedTimeRemaining: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private var shortFormattedTime: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = configuration.dateFormat
        formatter.timeZone = configuration.timeZone
        return formatter.string(from: liveShow.startDate)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = configuration.timeZone
        return formatter.string(from: liveShow.startDate)
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
        let remaining = liveShow.startDate.timeIntervalSinceNow
        
        if remaining <= 0 {
            timeRemaining = 0
            isLive = true
            stopTimer()
            configuration.onShowStarted?()
        } else {
            timeRemaining = remaining
        }
    }
}

// MARK: - Convenience Extensions

extension RLiveShowCountdown {
    /// Create countdown for show starting in hours
    public static func startsInHours(
        _ hours: Int,
        title: String,
        streamerName: String,
        style: CountdownStyle = .card
    ) -> RLiveShowCountdown {
        let startDate = Date().addingTimeInterval(TimeInterval(hours * 3600))
        
        return RLiveShowCountdown(
            liveShow: LiveShowSchedule(
                id: UUID().uuidString,
                title: title,
                streamerName: streamerName,
                startDate: startDate
            ),
            configuration: Configuration(style: style)
        )
    }
    
    /// Create countdown for show starting in days
    public static func startsInDays(
        _ days: Int,
        title: String,
        streamerName: String,
        style: CountdownStyle = .card
    ) -> RLiveShowCountdown {
        let startDate = Calendar.current.date(
            byAdding: .day,
            value: days,
            to: Date()
        ) ?? Date()
        
        return RLiveShowCountdown(
            liveShow: LiveShowSchedule(
                id: UUID().uuidString,
                title: title,
                streamerName: streamerName,
                startDate: startDate
            ),
            configuration: Configuration(
                style: style,
                showDaysWhenFar: true
            )
        )
    }
    
    /// Create minimal countdown for current live show
    public static func minimal(
        title: String,
        startDate: Date
    ) -> RLiveShowCountdown {
        RLiveShowCountdown(
            liveShow: LiveShowSchedule(
                id: UUID().uuidString,
                title: title,
                streamerName: "",
                startDate: startDate
            ),
            configuration: Configuration(
                style: .minimal,
                showDate: false,
                showTime: false
            )
        )
    }
}

// MARK: - Configuration Integration

extension RLiveShowCountdown.Configuration {
    /// Create configuration from Reachu configuration
    public static func fromReachuConfig() -> RLiveShowCountdown.Configuration {
        let _ = ReachuConfiguration.shared
        
        return RLiveShowCountdown.Configuration(
            style: .card,
            size: .medium,
            showDate: true,
            showTime: true,
            showDaysWhenFar: true,
            timeZone: .current,
            dateFormat: "MMM dd, yyyy" // Could be from config
        )
    }
    
    /// Create configuration for live streaming context
    public static func forLiveStreaming() -> RLiveShowCountdown.Configuration {
        RLiveShowCountdown.Configuration(
            style: .banner,
            size: .small,
            showDate: false,
            showTime: true,
            showDaysWhenFar: false
        )
    }
}

// MARK: - Preview

#Preview("Live Show Countdown - Styles") {
    VStack(spacing: ReachuSpacing.xl) {
        RLiveShowCountdown.startsInHours(
            5,
            title: "Beauty & Skincare Live Show",
            streamerName: "Sarah Johnson",
            style: .card
        )
        
        RLiveShowCountdown.startsInHours(
            2,
            title: "Fashion Week Special",
            streamerName: "Alex Chen",
            style: .banner
        )
        
        RLiveShowCountdown.minimal(
            title: "Tech Review Live",
            startDate: Date().addingTimeInterval(1800)
        )
        
        RLiveShowCountdown.startsInDays(
            2,
            title: "Holiday Shopping Event",
            streamerName: "Maria Rodriguez",
            style: .card
        )
    }
    .padding()
}

#Preview("Live Show Countdown - Sizes") {
    VStack(spacing: ReachuSpacing.lg) {
        HStack(spacing: ReachuSpacing.md) {
            RLiveShowCountdown(
                liveShow: RLiveShowCountdown.LiveShowSchedule(
                    id: "1",
                    title: "Live Show",
                    streamerName: "Host",
                    startDate: Date().addingTimeInterval(3600)
                ),
                configuration: RLiveShowCountdown.Configuration(size: .small)
            )
            
            RLiveShowCountdown(
                liveShow: RLiveShowCountdown.LiveShowSchedule(
                    id: "2", 
                    title: "Live Show",
                    streamerName: "Host",
                    startDate: Date().addingTimeInterval(3600)
                ),
                configuration: RLiveShowCountdown.Configuration(size: .medium)
            )
        }
        
        RLiveShowCountdown(
            liveShow: RLiveShowCountdown.LiveShowSchedule(
                id: "3",
                title: "Live Show",
                streamerName: "Host", 
                startDate: Date().addingTimeInterval(3600)
            ),
            configuration: RLiveShowCountdown.Configuration(size: .large)
        )
        
        Text("Size comparison")
            .font(.caption)
            .foregroundColor(.gray)
    }
    .padding()
}
