import Foundation
import SwiftUI
import ReachuDesignSystem

// Este App ya NO tiene @main - ahora es solo para organización
// El @main está en Sources/DemoApp/ para el executable
public struct DemoAppContent: App {
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            SimpleTestView()
        }
    }
}

// Vista simple para debugging
public struct SimpleTestView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
                   Text("Reachu SDK Demo")
                       .font(.largeTitle)
                       .fontWeight(.bold)
            
            Text("App funcionando correctamente")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Button("Test Button") {
                   print("Button funcionando")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .onAppear {
               print("SimpleTestView apareció correctamente")
        }
    }
}

#Preview {
    SimpleTestView()
}
