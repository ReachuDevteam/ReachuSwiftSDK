import Foundation
import SwiftUI

public struct CountdownBanner: DynamicComponentRenderable {
    private let component: DynamicComponent
    @State private var now: Date = Date()
    private var timer: Timer? = nil
    
    public init(component: DynamicComponent) {
        self.component = component
    }
    
    public var body: some View {
        VStack {
            Text(component.payload?["title"] ?? "Oferta termina en:")
                .font(.headline)
                .padding(.bottom, 4)
            Text(remainingText)
                .monospacedDigit()
                .font(.title2)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
    }
    
    private var remainingText: String {
        guard let end = component.endTime else { return "--:--:--" }
        let remaining = Int(max(0, end.timeIntervalSince(now)))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func startTimer() {
        let t = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            now = Date()
        }
        RunLoop.main.add(t, forMode: .common)
        t.fire()
    }
}

public struct PromoBanner: DynamicComponentRenderable {
    private let component: DynamicComponent
    
    public init(component: DynamicComponent) {
        self.component = component
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            if let emoji = component.payload?["emoji"] { Text(emoji) }
            Text(component.payload?["message"] ?? "Promoción activa")
                .font(.headline)
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

@MainActor public func registerDynamicComponentExamples() {
    DynamicComponentRegistry.shared.register(.countdown, as: CountdownBanner.self)
    DynamicComponentRegistry.shared.register(.banner, as: PromoBanner.self)
}

