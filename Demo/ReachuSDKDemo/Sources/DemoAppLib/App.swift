import Foundation
import SwiftUI
import ReachuDesignSystem

// Este App ya NO tiene @main - ahora es solo para organización
// El @main está en Sources/DemoApp/ para el executable
public struct DemoAppContent: App {
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupReachuSDK()
                }
        }
    }
    
    private func setupReachuSDK() {
        print("🚀 Reachu SDK Demo iniciado")
    }
}
