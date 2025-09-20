import SwiftUI
import ReachuDesignSystem

/// Toast notification system for cart actions and other feedback
/// 
/// Provides elegant, non-intrusive notifications with animations
/// Automatically dismisses after a set duration
public struct RToastNotification: View {
    
    public enum ToastType {
        case success
        case info
        case warning
        case error
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return ReachuColors.success
            case .info: return ReachuColors.info
            case .warning: return ReachuColors.warning
            case .error: return ReachuColors.error
            }
        }
    }
    
    let message: String
    let type: ToastType
    let duration: TimeInterval
    @Binding var isPresented: Bool
    
    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0
    
    public init(
        message: String,
        type: ToastType = .success,
        duration: TimeInterval = 3.0,
        isPresented: Binding<Bool>
    ) {
        self.message = message
        self.type = type
        self.duration = duration
        self._isPresented = isPresented
    }
    
    public var body: some View {
        if isPresented {
            VStack {
                HStack(spacing: ReachuSpacing.sm) {
                    // Icon
                    Image(systemName: type.icon)
                        .font(.title3)
                        .foregroundColor(type.color)
                    
                    // Message
                    Text(message)
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // Dismiss button
                    Button(action: {
                        dismissToast()
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(ReachuColors.textSecondary)
                    }
                }
                .padding(ReachuSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .offset(y: offset)
                .opacity(opacity)
                .onAppear {
                    showToast()
                }
                
                Spacer()
            }
            .padding(.horizontal, ReachuSpacing.lg)
            .padding(.top, ReachuSpacing.sm)
        }
    }
    
    private func showToast() {
        // Haptic feedback
        #if os(iOS)
        switch type {
        case .success:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)
        case .error:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.error)
        case .warning:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.warning)
        case .info:
            let feedback = UIImpactFeedbackGenerator(style: .light)
            feedback.impactOccurred()
        }
        #endif
        
        // Show animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            offset = 0
            opacity = 1
        }
        
        // Auto dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            dismissToast()
        }
    }
    
    private func dismissToast() {
        withAnimation(.easeInOut(duration: 0.3)) {
            offset = -100
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

/// Toast Manager for global toast notifications
@MainActor
public class ToastManager: ObservableObject {
    @Published public var currentToast: ToastData?
    @Published public var isPresented = false
    
    public static let shared = ToastManager()
    private init() {}
    
    public struct ToastData {
        let message: String
        let type: RToastNotification.ToastType
        let duration: TimeInterval
        
        public init(message: String, type: RToastNotification.ToastType = .success, duration: TimeInterval = 3.0) {
            self.message = message
            self.type = type
            self.duration = duration
        }
    }
    
    public func show(_ message: String, type: RToastNotification.ToastType = .success, duration: TimeInterval = 3.0) {
        currentToast = ToastData(message: message, type: type, duration: duration)
        isPresented = true
    }
    
    public func showSuccess(_ message: String) {
        show(message, type: .success)
    }
    
    public func showError(_ message: String) {
        show(message, type: .error)
    }
    
    public func showInfo(_ message: String) {
        show(message, type: .info)
    }
    
    public func showWarning(_ message: String) {
        show(message, type: .warning)
    }
    
    public func dismiss() {
        isPresented = false
    }
}

/// Global toast overlay that can be used anywhere in the app
public struct RToastOverlay: View {
    @StateObject private var toastManager = ToastManager.shared
    
    public init() {}
    
    public var body: some View {
        if let toast = toastManager.currentToast {
            RToastNotification(
                message: toast.message,
                type: toast.type,
                duration: toast.duration,
                isPresented: $toastManager.isPresented
            )
        }
    }
}

// MARK: - Previews
#if DEBUG

#Preview("Toast Success") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        VStack {
            Text("App Content")
                .font(.title)
            Spacer()
        }
        
        RToastNotification(
            message: "Product added to cart successfully!",
            type: .success,
            isPresented: .constant(true)
        )
    }
}

#Preview("Toast Error") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        VStack {
            Text("App Content")
                .font(.title)
            Spacer()
        }
        
        RToastNotification(
            message: "Failed to add product to cart. Please try again.",
            type: .error,
            isPresented: .constant(true)
        )
    }
}

#Preview("Toast Manager Demo") {
    VStack(spacing: ReachuSpacing.lg) {
        Text("Toast Manager Demo")
            .font(.title)
        
        VStack(spacing: ReachuSpacing.md) {
            RButton(title: "Show Success Toast", style: .primary) {
                ToastManager.shared.showSuccess("Product added to cart!")
            }
            
            RButton(title: "Show Error Toast", style: .destructive) {
                ToastManager.shared.showError("Something went wrong!")
            }
            
            RButton(title: "Show Info Toast", style: .secondary) {
                ToastManager.shared.showInfo("Cart updated successfully")
            }
            
            RButton(title: "Show Warning Toast", style: .tertiary) {
                ToastManager.shared.showWarning("Low stock remaining")
            }
        }
        
        Spacer()
    }
    .padding()
    .overlay {
        RToastOverlay()
    }
}

#endif
