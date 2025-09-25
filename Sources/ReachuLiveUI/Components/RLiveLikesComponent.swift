import SwiftUI
import ReachuCore
import ReachuDesignSystem

#if os(iOS)
import UIKit
#endif

/// Live likes component with flying heart animations
public struct RLiveLikesComponent: View {
    
    // MARK: - Properties
    @ObservedObject private var likesManager: LiveLikesManager
    @Environment(\.colorScheme) private var colorScheme
    
    // Colors based on theme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    public init(likesManager: LiveLikesManager? = nil) {
        self.likesManager = likesManager ?? LiveLikesManager.shared
    }
    
    // MARK: - Body
    public var body: some View {
        ZStack {
            // Flying hearts overlay
            ForEach(likesManager.flyingHearts) { heart in
                FlyingHeart(heart: heart)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
            }
            
            // Tap area for likes (covers right side of screen)
            HStack {
                Spacer()
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 100) // Smaller tap area to avoid conflicts
                    .contentShape(Rectangle())
                    .onTapGesture {
                        createLike()
                    }
            }
        }
        .onAppear {
            likesManager.startAutoLikes()
        }
        .onDisappear {
            likesManager.stopAutoLikes()
        }
    }
    
    // MARK: - Create Like
    
    private func createLike() {
        let heart = FlyingHeartModel(
            id: UUID().uuidString,
            startPosition: CGPoint(
                x: 350, // Fixed position for right side
                y: CGFloat.random(in: 300...600)
            ),
            isUserGenerated: true
        )
        
        likesManager.addHeart(heart)
        
        // Haptic feedback
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
        
        print("❤️ [Likes] User created like")
    }
}

// MARK: - Flying Heart View

struct FlyingHeart: View {
    let heart: FlyingHeartModel
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1.0
    @State private var scale: Double = 0.1
    
    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: CGFloat.random(in: 16...28)))
            .foregroundColor(.red)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(offset)
            .position(heart.startPosition)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    scale = 1.0
                }
                
                withAnimation(.easeOut(duration: 3.0)) {
                    offset = CGSize(
                        width: CGFloat.random(in: -30...30),
                        height: -CGFloat.random(in: 200...400)
                    )
                    opacity = 0.0
                }
                
                // Remove heart after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    LiveLikesManager.shared.removeHeart(heart.id)
                }
            }
    }
}

// MARK: - Flying Heart Model

public struct FlyingHeartModel: Identifiable {
    public let id: String
    public let startPosition: CGPoint
    public let isUserGenerated: Bool
    public let timestamp: Date
    
    public init(id: String, startPosition: CGPoint, isUserGenerated: Bool) {
        self.id = id
        self.startPosition = startPosition
        self.isUserGenerated = isUserGenerated
        self.timestamp = Date()
    }
}

// MARK: - Live Likes Manager

@MainActor
public class LiveLikesManager: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = LiveLikesManager()
    
    // MARK: - Published Properties
    @Published public private(set) var flyingHearts: [FlyingHeartModel] = []
    @Published public private(set) var totalLikes: Int = 0
    
    // MARK: - Private Properties
    private var autoLikesTimer: Timer?
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Add a flying heart
    public func addHeart(_ heart: FlyingHeartModel) {
        flyingHearts.append(heart)
        totalLikes += 1
        
        // Keep only last 20 hearts for performance
        if flyingHearts.count > 20 {
            flyingHearts = Array(flyingHearts.suffix(20))
        }
    }
    
    /// Remove a heart by ID
    public func removeHeart(_ id: String) {
        flyingHearts.removeAll { $0.id == id }
    }
    
    /// Start automatic likes simulation
    public func startAutoLikes() {
        stopAutoLikes() // Ensure no duplicate timers
        
        autoLikesTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 2...5), repeats: true) { _ in
            Task { @MainActor in
                self.simulateAutoLike()
                
                // Reschedule with random interval
                self.autoLikesTimer?.invalidate()
                self.autoLikesTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 2...5), repeats: true) { _ in
                    Task { @MainActor in
                        self.simulateAutoLike()
                    }
                }
            }
        }
        
        print("❤️ [Likes] Auto likes simulation started")
    }
    
    /// Stop automatic likes simulation
    public func stopAutoLikes() {
        autoLikesTimer?.invalidate()
        autoLikesTimer = nil
        print("❤️ [Likes] Auto likes simulation stopped")
    }
    
    /// Clear all hearts
    public func clearHearts() {
        flyingHearts.removeAll()
        print("❤️ [Likes] Hearts cleared")
    }
    
    // MARK: - Private Methods
    
    private func simulateAutoLike() {
        let heart = FlyingHeartModel(
            id: UUID().uuidString,
            startPosition: CGPoint(
                x: CGFloat.random(in: 100...300),
                y: CGFloat.random(in: 400...700)
            ),
            isUserGenerated: false
        )
        
        addHeart(heart)
        print("❤️ [Likes] Auto-generated like")
    }
    
    deinit {
        Task { @MainActor in
            self.stopAutoLikes()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        RLiveLikesComponent()
    }
}
