import SwiftUI
import ReachuCore
import ReachuLiveUI
import ReachuDesignSystem
import ReachuUI

struct CampaignComponentsDemoView: View {
    
    @EnvironmentObject var cartManager: CartManager
    @Environment(\.colorScheme) private var colorScheme
    
    // Colors based on theme and color scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    // MARK: - State
    @State private var selectedStockCount = 5
    @State private var selectedDiscountPercentage = 25
    @State private var selectedCountdownDuration = 1800.0 // 30 minutes
    @State private var showFlashSaleBanner = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: ReachuSpacing.xl) {
                
                // Header
                headerSection
                
                // Stock Alert Demo
                stockAlertSection
                
                // Live Show Countdown Demo
                liveShowCountdownSection
                
                // Countdown Timer Demo
                countdownTimerSection
                
                // Flash Sale Banner Demo
                flashSaleBannerSection
                
                // Combined Usage Example
                combinedUsageSection
                
            }
            .padding(.horizontal, ReachuSpacing.lg)
            .padding(.vertical, ReachuSpacing.md)
        }
        .background(adaptiveColors.background)
        .navigationTitle("Campaign Components")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: ReachuSpacing.sm) {
            Text("🎪 Campaign Components")
                .font(ReachuTypography.title1)
                .foregroundColor(adaptiveColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Components for creating urgency, promoting offers, and enhancing campaign effectiveness.")
                .font(ReachuTypography.body)
                .foregroundColor(adaptiveColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, ReachuSpacing.lg)
    }
    
    // MARK: - Stock Alert Section
    
    private var stockAlertSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text("🚨 Stock Alerts")
                .font(ReachuTypography.headline)
                .foregroundColor(adaptiveColors.textPrimary)
            
            Text("Create urgency with low stock warnings")
                .font(ReachuTypography.body)
                .foregroundColor(adaptiveColors.textSecondary)
            
            // Stock count selector
            VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                Text("Stock Count: \(selectedStockCount)")
                    .font(ReachuTypography.bodyBold)
                    .foregroundColor(adaptiveColors.textPrimary)
                
                Slider(value: Binding(
                    get: { Double(selectedStockCount) },
                    set: { selectedStockCount = Int($0) }
                ), in: 0...20, step: 1)
                .accentColor(adaptiveColors.primary)
            }
            
            // Stock alert examples
            VStack(spacing: ReachuSpacing.sm) {
                RStockAlert(stockCount: selectedStockCount, style: .warning)
                RStockAlert(
                    stockCount: selectedStockCount,
                    configuration: RStockAlert.Configuration(
                        style: .critical,
                        animation: .pulse
                    )
                )
                RStockAlert(
                    stockCount: selectedStockCount,
                    configuration: RStockAlert.Configuration(
                        style: .warning,
                        animation: .shake
                    )
                )
            }
        }
        .padding(ReachuSpacing.lg)
        .background(adaptiveColors.surface)
        .cornerRadius(ReachuBorderRadius.medium)
        .shadow(color: adaptiveColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Live Show Countdown Section
    
    private var liveShowCountdownSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text("📺 Live Show Countdown")
                .font(ReachuTypography.headline)
                .foregroundColor(adaptiveColors.textPrimary)
            
            Text("Show when live shows start with configurable countdown")
                .font(ReachuTypography.body)
                .foregroundColor(adaptiveColors.textSecondary)
            
            // Live show countdown examples
            VStack(spacing: ReachuSpacing.md) {
                Text("Styles:")
                    .font(ReachuTypography.bodyBold)
                    .foregroundColor(adaptiveColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Card style (main style)
                RLiveShowCountdown.startsInHours(
                    5,
                    title: "Beauty & Skincare Live Show",
                    streamerName: "Sarah Johnson",
                    style: .card
                )
                
                // Banner style (compact)
                RLiveShowCountdown.startsInHours(
                    2,
                    title: "Fashion Week Special",
                    streamerName: "Alex Chen",
                    style: .banner
                )
                
                // Minimal style
                RLiveShowCountdown.minimal(
                    title: "Tech Review Live",
                    startDate: Date().addingTimeInterval(1800)
                )
                
                Text("Far Future (Days):")
                    .font(ReachuTypography.bodyBold)
                    .foregroundColor(adaptiveColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Days countdown
                RLiveShowCountdown.startsInDays(
                    3,
                    title: "Holiday Shopping Event",
                    streamerName: "Maria Rodriguez",
                    style: .card
                )
            }
        }
        .padding(ReachuSpacing.lg)
        .background(adaptiveColors.surface)
        .cornerRadius(ReachuBorderRadius.medium)
        .shadow(color: adaptiveColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Countdown Timer Section
    
    private var countdownTimerSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text("⏰ Countdown Timers")
                .font(ReachuTypography.headline)
                .foregroundColor(adaptiveColors.textPrimary)
            
            Text("Create urgency with time-limited offers")
                .font(ReachuTypography.body)
                .foregroundColor(adaptiveColors.textSecondary)
            
            // Duration selector
            VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                Text("Duration: \(Int(selectedCountdownDuration / 60)) minutes")
                    .font(ReachuTypography.bodyBold)
                    .foregroundColor(adaptiveColors.textPrimary)
                
                Slider(value: $selectedCountdownDuration, in: 60...7200, step: 60) // 1min to 2h
                    .accentColor(adaptiveColors.primary)
            }
            
            // Timer styles
            VStack(spacing: ReachuSpacing.lg) {
                Text("Styles:")
                    .font(ReachuTypography.bodyBold)
                    .foregroundColor(adaptiveColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: ReachuSpacing.md) {
                    HStack(spacing: ReachuSpacing.lg) {
                        VStack {
                            Text("Digital")
                                .font(ReachuTypography.caption1)
                                .foregroundColor(adaptiveColors.textSecondary)
                            RCountdownTimer(duration: selectedCountdownDuration, style: .digital)
                        }
                        
                        VStack {
                            Text("Blocks")
                                .font(ReachuTypography.caption1)
                                .foregroundColor(adaptiveColors.textSecondary)
                            RCountdownTimer(duration: selectedCountdownDuration, style: .blocks)
                        }
                    }
                    
                    HStack(spacing: ReachuSpacing.lg) {
                        VStack {
                            Text("Circular")
                                .font(ReachuTypography.caption1)
                                .foregroundColor(adaptiveColors.textSecondary)
                            RCountdownTimer(duration: selectedCountdownDuration, style: .circular, size: .medium)
                        }
                        
                        VStack {
                            Text("Minimal")
                                .font(ReachuTypography.caption1)
                                .foregroundColor(adaptiveColors.textSecondary)
                            RCountdownTimer(duration: selectedCountdownDuration, style: .minimal)
                        }
                    }
                }
            }
        }
        .padding(ReachuSpacing.lg)
        .background(adaptiveColors.surface)
        .cornerRadius(ReachuBorderRadius.medium)
        .shadow(color: adaptiveColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Flash Sale Banner Section
    
    private var flashSaleBannerSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text("🎪 Flash Sale Banners")
                .font(ReachuTypography.headline)
                .foregroundColor(adaptiveColors.textPrimary)
            
            Text("Promotional banners for campaigns and live shows")
                .font(ReachuTypography.body)
                .foregroundColor(adaptiveColors.textSecondary)
            
            // Banner examples
            VStack(spacing: ReachuSpacing.md) {
                if showFlashSaleBanner {
                    RFlashSaleBanner.withCountdown(
                        title: "FLASH SALE",
                        discount: "50% OFF",
                        duration: selectedCountdownDuration
                    ) {
                        print("Flash sale banner tapped!")
                    }
                }
                
                RFlashSaleBanner(
                    flashSale: RFlashSaleBanner.FlashSale(
                        title: "MEGA SALE",
                        subtitle: "Everything must go!",
                        discount: "UP TO 70% OFF",
                        endDate: Date().addingTimeInterval(selectedCountdownDuration),
                        backgroundColor: .purple
                    ),
                    configuration: RFlashSaleBanner.Configuration(
                        style: .gradient,
                        size: .large,
                        animation: .glow
                    )
                ) {
                    print("Mega sale banner tapped!")
                }
                
                RFlashSaleBanner.minimal(
                    title: "WEEKEND SPECIAL",
                    discount: "25% OFF"
                ) {
                    print("Weekend special tapped!")
                }
            }
            
            // Toggle button
            Button(showFlashSaleBanner ? "Hide Flash Sale" : "Show Flash Sale") {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showFlashSaleBanner.toggle()
                }
            }
            .font(ReachuTypography.body)
            .foregroundColor(adaptiveColors.primary)
        }
        .padding(ReachuSpacing.lg)
        .background(adaptiveColors.surface)
        .cornerRadius(ReachuBorderRadius.medium)
        .shadow(color: adaptiveColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Combined Usage Section
    
    private var combinedUsageSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text("🎯 Combined Usage Example")
                .font(ReachuTypography.headline)
                .foregroundColor(adaptiveColors.textPrimary)
            
            Text("How components work together in real scenarios")
                .font(ReachuTypography.body)
                .foregroundColor(adaptiveColors.textSecondary)
            
            // Product card with campaign components
            productCardWithCampaignComponents
            
            // Live show banner example
            liveShowBannerExample
        }
        .padding(ReachuSpacing.lg)
        .background(adaptiveColors.surface)
        .cornerRadius(ReachuBorderRadius.medium)
        .shadow(color: adaptiveColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Product Card Example
    
    private var productCardWithCampaignComponents: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
            Text("Product with Campaign Components:")
                .font(ReachuTypography.bodyBold)
                .foregroundColor(adaptiveColors.textPrimary)
            
            ZStack {
                // Mock product card
                VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                    // Product image placeholder
                    Rectangle()
                        .fill(adaptiveColors.surfaceSecondary)
                        .frame(height: 120)
                        .cornerRadius(ReachuBorderRadius.medium)
                        .overlay {
                            Text("Product Image")
                                .font(ReachuTypography.caption1)
                                .foregroundColor(adaptiveColors.textSecondary)
                        }
                    
                    // Product info
                    VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                        Text("Reachu Wireless Headphones")
                            .font(ReachuTypography.bodyBold)
                            .foregroundColor(adaptiveColors.textPrimary)
                        
                        HStack {
                            Text("$199.99")
                                .font(ReachuTypography.body)
                                .foregroundColor(adaptiveColors.primary)
                            
                            Text("$249.99")
                                .font(ReachuTypography.caption1)
                                .foregroundColor(adaptiveColors.textSecondary)
                                .strikethrough()
                        }
                        
                        // Stock alert
                        RStockAlert(
                            stockCount: 3,
                            configuration: RStockAlert.Configuration(
                                style: .critical,
                                animation: .pulse
                            )
                        )
                    }
                    .padding(ReachuSpacing.sm)
                }
                .background(adaptiveColors.surface)
                .cornerRadius(ReachuBorderRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                        .stroke(adaptiveColors.border, lineWidth: 1)
                )
                
                // Live show countdown overlay
                VStack {
                    HStack {
                        Spacer()
                        RLiveShowCountdown(
                            liveShow: RLiveShowCountdown.LiveShowSchedule(
                                id: "demo",
                                title: "Live Sale",
                                streamerName: "Host",
                                startDate: Date().addingTimeInterval(3600)
                            ),
                            configuration: RLiveShowCountdown.Configuration(
                                style: .badge,
                                size: .small
                            )
                        )
                        .offset(x: -8, y: 8)
                    }
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Live Show Banner Example
    
    private var liveShowBannerExample: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
            Text("Live Show Campaign:")
                .font(ReachuTypography.bodyBold)
                .foregroundColor(adaptiveColors.textPrimary)
            
            VStack(spacing: ReachuSpacing.sm) {
                // Flash sale banner
                RFlashSaleBanner(
                    flashSale: RFlashSaleBanner.FlashSale(
                        title: "LIVE SALE",
                        subtitle: "Exclusive for live viewers",
                        discount: "40% OFF",
                        endDate: Date().addingTimeInterval(900), // 15 minutes
                        backgroundColor: .red
                    ),
                    configuration: RFlashSaleBanner.Configuration(
                        style: .gradient,
                        size: .medium,
                        animation: .glow,
                        showCountdown: true
                    )
                ) {
                    print("Live sale banner tapped!")
                }
                
                // Countdown timer for live show
                HStack {
                    Text("Show ends in:")
                        .font(ReachuTypography.body)
                        .foregroundColor(adaptiveColors.textSecondary)
                    
                    Spacer()
                    
                    RCountdownTimer(
                        duration: 2700, // 45 minutes
                        style: .digital,
                        size: .small
                    )
                }
                .padding(.horizontal, ReachuSpacing.md)
                .padding(.vertical, ReachuSpacing.sm)
                .background(adaptiveColors.surfaceSecondary)
                .cornerRadius(ReachuBorderRadius.small)
            }
        }
    }
    
    // MARK: - Configuration Section
    
    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text("⚙️ Configuration Options")
                .font(ReachuTypography.headline)
                .foregroundColor(adaptiveColors.textPrimary)
            
            Text("All components are highly configurable")
                .font(ReachuTypography.body)
                .foregroundColor(adaptiveColors.textSecondary)
            
            VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                configurationExample(
                    title: "RStockAlert",
                    description: "threshold, style, animation, showExactCount"
                )
                
                configurationExample(
                    title: "RDiscountBadge", 
                    description: "style, size, animation, position"
                )
                
                configurationExample(
                    title: "RCountdownTimer",
                    description: "style, size, urgencyThreshold, onExpired"
                )
                
                configurationExample(
                    title: "RFlashSaleBanner",
                    description: "style, size, animation, showCountdown, isDismissible"
                )
            }
        }
        .padding(ReachuSpacing.lg)
        .background(adaptiveColors.surface)
        .cornerRadius(ReachuBorderRadius.medium)
        .shadow(color: adaptiveColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func configurationExample(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            Text(title)
                .font(ReachuTypography.bodyBold)
                .foregroundColor(adaptiveColors.textPrimary)
            
            Text(description)
                .font(ReachuTypography.caption1)
                .foregroundColor(adaptiveColors.textSecondary)
        }
        .padding(ReachuSpacing.sm)
        .background(adaptiveColors.surfaceSecondary)
        .cornerRadius(ReachuBorderRadius.small)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        CampaignComponentsDemoView()
            .environmentObject(CartManager())
    }
}
