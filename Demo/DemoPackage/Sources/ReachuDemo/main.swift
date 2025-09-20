import SwiftUI

@main
struct ReachuDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("Reachu SDK Demo App launched")
                }
        }
    }
}
