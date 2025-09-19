import Foundation
import SwiftUI
import ReachuDesignSystem

@main
public struct DemoApp: App {
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
