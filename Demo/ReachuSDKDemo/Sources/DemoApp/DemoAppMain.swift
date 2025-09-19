import SwiftUI
import DemoAppLib

@main
struct DemoAppMain: App {
    var body: some Scene {
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
