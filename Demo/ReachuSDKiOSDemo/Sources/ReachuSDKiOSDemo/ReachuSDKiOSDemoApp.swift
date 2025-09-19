import SwiftUI
import ReachuDesignSystem
import ReachuCore

@main
public struct ReachuSDKiOSDemoApp: App {
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
        print("🚀 Reachu SDK iOS Demo iniciado")
        // TODO: Inicializar ReachuCore cuando esté implementado
    }
}
