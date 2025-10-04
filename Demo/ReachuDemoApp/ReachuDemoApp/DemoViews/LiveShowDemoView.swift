import SwiftUI
import ReachuCore
import ReachuLiveShow
import ReachuDesignSystem
import ReachuUI
import ReachuTesting
import ReachuLiveUI

struct LiveShowDemoView: View {
    
    @ObservedObject private var liveShowManager = LiveShowManager.shared
    @EnvironmentObject var cartManager: CartManager
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedLayout: LiveStreamLayout = .fullScreenOverlay
    @State private var selectedStream: LiveStream?
    
    @State private var hasLoadedInitialComponents: Bool = false 
    // Colors based on theme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: ReachuSpacing.xl) {
                
                // Header
                headerSection
                
                // Live streams available
                activeStreamsSection
                
                // Main action button
                showLiveStreamSection
                
            }
            .padding(.horizontal, ReachuSpacing.lg)
            .padding(.vertical, ReachuSpacing.md)
        }
        .background(adaptiveColors.background)
        .navigationTitle("Live Show")
        .navigationBarTitleDisplayMode(.inline)
        //.onAppear {
            //selectedStream = liveShowManager.featuredLiveStream
            //// Cargar componentes dinámicos desde API (reemplaza la URL/header en el servicio si es necesario)
            //Task { @MainActor in
                //do {
                    //DynamicComponentManager.shared.reset()
                    //print("[DynamicDemo] selectedStream?.id \(String(describing: selectedStream?.id))")
                    //let components = try await DynamicComponentsService.fetch(for: selectedStream?.id)
                    //print("[DynamicDemo] Remote components count=\(components.count)")
                    //DynamicComponentManager.shared.register(components)
                //} catch {
                    //print("[DynamicDemo][ERROR] fetch dynamic components: \(error)")
                //}
            //}
        //}
        .onAppear {
            if !liveShowManager.activeStreams.isEmpty && !hasLoadedInitialComponents {
                loadDynamicComponents()
            }
        } 
        .onChange(of: liveShowManager.activeStreams) { newStreams in            
            if !newStreams.isEmpty && !hasLoadedInitialComponents {
                loadDynamicComponents()
            }
        }      
    }

    private func loadDynamicComponents() {
        guard !liveShowManager.activeStreams.isEmpty else { return }

        // 2. Establecer el stream destacado/primero
        let streamToSelect = liveShowManager.featuredLiveStream ?? liveShowManager.activeStreams.first
        selectedStream = streamToSelect
        
        // 3. Cargar los componentes dinámicos
        Task { @MainActor in
            do {
                DynamicComponentManager.shared.reset()
                print("[DynamicDemo] selectedStream?.id \(String(describing: streamToSelect?.id))")
                let components = try await DynamicComponentsService.fetch(for: streamToSelect?.id)
                print("[DynamicDemo] Remote components count=\(components.count)")
                DynamicComponentManager.shared.register(components)

                // Only set the flag after a successful attempt
                hasLoadedInitialComponents = true 
            } catch {
                print("[DynamicDemo][ERROR] fetch dynamic components: \(error)")
                // It's still safer to set the flag to true here to avoid retrying on every minor array update.
                hasLoadedInitialComponents = true 
            }
        }
    }    
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: ReachuSpacing.sm) {
            Text("🎬 Live Show Experience")
                .font(ReachuTypography.title1)
                .foregroundColor(adaptiveColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Interactive live streaming with shopping integration. Test all 3 layouts and see how the global overlay system works.")
                .font(ReachuTypography.body)
                .foregroundColor(adaptiveColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Active Streams Section
    
    private var activeStreamsSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text("📺 Available Live Streams")
                .font(ReachuTypography.headline)
                .foregroundColor(adaptiveColors.textPrimary)
            
            if liveShowManager.activeStreams.isEmpty {
                Text("No active streams")
                    .font(ReachuTypography.body)
                    .foregroundColor(adaptiveColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, ReachuSpacing.lg)
            } else {
                ForEach(liveShowManager.activeStreams, id: \.id) { stream in
                    streamCard(stream)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func streamCard(_ stream: LiveStream) -> some View {
        Button(action: {
            selectedStream = stream
        }) {
            HStack(spacing: ReachuSpacing.md) {
                // Thumbnail
                AsyncImage(url: URL(string: stream.thumbnailUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(adaptiveColors.surfaceSecondary)
                }
                .frame(width: 80, height: 60)
                .cornerRadius(ReachuBorderRadius.medium)
                .clipped()
                .overlay(
                    VStack {
                        HStack {
                            if stream.isLive {
                                HStack(spacing: 2) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 4, height: 4)
                                    Text("LIVE")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(6)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(4)
                )
                
                // Stream info
                VStack(alignment: .leading, spacing: 4) {
                    Text(stream.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(adaptiveColors.textPrimary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 4) {
                        AsyncImage(url: URL(string: stream.streamer.avatarUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle().fill(adaptiveColors.surfaceSecondary)
                        }
                        .frame(width: 16, height: 16)
                        .clipShape(Circle())
                        
                        Text(stream.streamer.name)
                            .font(.system(size: 12))
                            .foregroundColor(adaptiveColors.textSecondary)
                        
                        if stream.streamer.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 10))
                        }
                    }
                    
                    Text("\(stream.viewerCount) viewers • \(stream.featuredProducts.count) products")
                        .font(.system(size: 11))
                        .foregroundColor(adaptiveColors.textTertiary)
                }
                
                Spacer()
                
                // Selection indicator
                if selectedStream?.id == stream.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(adaptiveColors.primary)
                        .font(.system(size: 20))
                }
            }
            .padding(ReachuSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                    .fill(adaptiveColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                            .stroke(
                                selectedStream?.id == stream.id ? adaptiveColors.primary : adaptiveColors.border,
                                lineWidth: selectedStream?.id == stream.id ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Layout Selector Section
    
    private var layoutSelectorSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text("📱 Layout Options")
                .font(ReachuTypography.headline)
                .foregroundColor(adaptiveColors.textPrimary)
            
            VStack(spacing: ReachuSpacing.sm) {
                ForEach(LiveStreamLayout.allCases, id: \.rawValue) { layout in
                    layoutOption(layout)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func layoutOption(_ layout: LiveStreamLayout) -> some View {
        Button(action: {
            selectedLayout = layout
        }) {
            HStack(spacing: ReachuSpacing.md) {
                // Layout icon
                Image(systemName: layoutIcon(for: layout))
                    .font(.system(size: 20))
                    .foregroundColor(selectedLayout == layout ? .white : adaptiveColors.primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(selectedLayout == layout ? adaptiveColors.primary : adaptiveColors.primary.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(layout.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(adaptiveColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(layoutDescription(for: layout))
                        .font(.system(size: 12))
                        .foregroundColor(adaptiveColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                if selectedLayout == layout {
                    Image(systemName: "checkmark")
                        .foregroundColor(adaptiveColors.primary)
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .padding(ReachuSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                    .fill(adaptiveColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                            .stroke(
                                selectedLayout == layout ? adaptiveColors.primary : adaptiveColors.border,
                                lineWidth: selectedLayout == layout ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func layoutIcon(for layout: LiveStreamLayout) -> String {
        switch layout {
        case .fullScreenOverlay: return "rectangle.fill"
        case .bottomSheet: return "rectangle.bottomthird.inset.filled"
        case .modal: return "rectangle.portrait"
        }
    }
    
    private func layoutDescription(for layout: LiveStreamLayout) -> String {
        switch layout {
        case .fullScreenOverlay: return "TikTok/Instagram style - Full screen immersive experience"
        case .bottomSheet: return "Bottom drawer - Video preview with expandable controls"
        case .modal: return "Modal sheet - Traditional video player with tabs"
        }
    }
    
    // MARK: - Control Buttons Section
    
    private var controlButtonsSection: some View {
        VStack(spacing: ReachuSpacing.md) {
            Text("🎛️ Controls")
                .font(ReachuTypography.headline)
                .foregroundColor(adaptiveColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: ReachuSpacing.sm) {
                // Show Live Stream button
                Button(action: {
                    guard let stream = selectedStream else { return }
                    liveShowManager.showLiveStream(stream, layout: selectedLayout)
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Show Live Stream")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ReachuSpacing.md)
                    .background(adaptiveColors.primary)
                    .cornerRadius(ReachuBorderRadius.large)
                }
                .disabled(selectedStream == nil)
                
                // Mini Player button
                Button(action: {
                    if liveShowManager.isLiveShowVisible {
                        liveShowManager.showMiniPlayer()
                    } else if let stream = selectedStream {
                        liveShowManager.showLiveStream(stream, layout: selectedLayout)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            liveShowManager.showMiniPlayer()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "pip.enter")
                        Text("Show Mini Player")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(adaptiveColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ReachuSpacing.md)
                    .background(adaptiveColors.primary.opacity(0.1))
                    .cornerRadius(ReachuBorderRadius.large)
                }
                .disabled(selectedStream == nil)
                
                // Hide Stream button
                Button(action: {
                    liveShowManager.hideLiveStream()
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Hide Stream")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(adaptiveColors.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ReachuSpacing.md)
                    .background(adaptiveColors.error.opacity(0.1))
                    .cornerRadius(ReachuBorderRadius.large)
                }
                .disabled(!liveShowManager.isWatchingLiveStream)
            }
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text("📊 Current Status")
                .font(ReachuTypography.headline)
                .foregroundColor(adaptiveColors.textPrimary)
            
            VStack(spacing: ReachuSpacing.sm) {
                statusRow("Live Stream Visible", value: liveShowManager.isLiveShowVisible ? "Yes" : "No")
                statusRow("Mini Player Visible", value: liveShowManager.isMiniPlayerVisible ? "Yes" : "No")
                statusRow("Indicator Visible", value: liveShowManager.isIndicatorVisible ? "Yes" : "No")
                statusRow("Active Streams", value: "\(liveShowManager.activeStreams.count)")
                statusRow("Total Viewers", value: "\(liveShowManager.totalViewerCount)")
                statusRow("Current Layout", value: liveShowManager.layout.displayName)
                
                if let currentStream = liveShowManager.currentStream {
                    statusRow("Current Stream", value: currentStream.title)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func statusRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(adaptiveColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(adaptiveColors.textPrimary)
        }
        .padding(.horizontal, ReachuSpacing.md)
        .padding(.vertical, ReachuSpacing.sm)
        .background(adaptiveColors.surfaceSecondary)
        .cornerRadius(ReachuBorderRadius.medium)
    }
    
    // MARK: - Demo Actions Section
    
    private var demoActionsSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text("🧪 Demo Actions")
                .font(ReachuTypography.headline)
                .foregroundColor(adaptiveColors.textPrimary)
            
            VStack(spacing: ReachuSpacing.sm) {
                Button(action: {
                    liveShowManager.simulateNewChatMessage()
                }) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                        Text("Simulate Chat Message")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(adaptiveColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ReachuSpacing.sm)
                    .background(adaptiveColors.surfaceSecondary)
                    .cornerRadius(ReachuBorderRadius.medium)
                }
                
                Button(action: {
                    liveShowManager.toggleIndicator()
                }) {
                    HStack {
                        Image(systemName: liveShowManager.isIndicatorVisible ? "eye.slash" : "eye")
                        Text(liveShowManager.isIndicatorVisible ? "Hide Indicator" : "Show Indicator")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(adaptiveColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ReachuSpacing.sm)
                    .background(adaptiveColors.surfaceSecondary)
                    .cornerRadius(ReachuBorderRadius.medium)
                }
                
                if let stream = selectedStream, !stream.featuredProducts.isEmpty {
                    Button(action: {
                        let product = stream.featuredProducts.randomElement()!
                        liveShowManager.addProductToCart(product, cartManager: cartManager)
                    }) {
                        HStack {
                            Image(systemName: "cart.badge.plus")
                            Text("Add Random Product")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(adaptiveColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ReachuSpacing.sm)
                        .background(adaptiveColors.surfaceSecondary)
                        .cornerRadius(ReachuBorderRadius.medium)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Live Stream Card
    
    @ViewBuilder
    private var showLiveStreamSection: some View {
        if let stream = liveShowManager.activeStreams.first {
            Button(action: {
                liveShowManager.showLiveStream(stream, layout: .fullScreenOverlay)
            }) {
                HStack(spacing: ReachuSpacing.md) {
                    // Thumbnail
                    AsyncImage(url: URL(string: stream.thumbnailUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(adaptiveColors.surfaceSecondary)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(ReachuBorderRadius.medium)
                    .clipped()
                    
                    // Stream info
                    VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                        // Title
                        Text(stream.title)
                            .font(ReachuTypography.headline)
                            .foregroundColor(adaptiveColors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        // Streamer
                        Text("by \(stream.streamer.name)")
                            .font(ReachuTypography.body)
                            .foregroundColor(adaptiveColors.textSecondary)
                        
                        // Status
                        HStack(spacing: ReachuSpacing.xs) {
                            Circle()
                                .fill(stream.isLive ? Color.red : Color.gray)
                                .frame(width: 8, height: 8)
                            
                            Text(stream.isLive ? "LIVE" : "OFFLINE")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(stream.isLive ? Color.red : Color.gray)
                        }
                        
                        // Viewer count
                        if stream.viewerCount > 0 {
                            HStack(spacing: ReachuSpacing.xs) {
                                Image(systemName: "eye.fill")
                                    .font(.caption2)
                                    .foregroundColor(adaptiveColors.textSecondary)
                                
                                Text("\(stream.viewerCount) watching")
                                    .font(.caption)
                                    .foregroundColor(adaptiveColors.textSecondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Arrow indicator
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(adaptiveColors.textTertiary)
                }
                .padding(ReachuSpacing.lg)
                .background(adaptiveColors.surface)
                .cornerRadius(ReachuBorderRadius.medium)
                .shadow(color: adaptiveColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            // No stream available
            VStack(spacing: ReachuSpacing.md) {
                Text("No Live Stream Available")
                    .font(ReachuTypography.headline)
                    .foregroundColor(adaptiveColors.textSecondary)
                
                Text("Demo stream data is loading...")
                    .font(ReachuTypography.body)
                    .foregroundColor(adaptiveColors.textTertiary)
            }
            .padding(ReachuSpacing.xl)
            .background(adaptiveColors.surface)
            .cornerRadius(ReachuBorderRadius.medium)
        }
    }
}

// MARK: - Previews

#Preview("Live Show Demo") {
    NavigationView {
        LiveShowDemoView()
            .environmentObject(CartManager())
    }
    .navigationViewStyle(StackNavigationViewStyle())
}

