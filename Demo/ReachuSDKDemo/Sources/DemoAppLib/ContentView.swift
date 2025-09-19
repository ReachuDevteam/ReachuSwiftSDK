import Foundation
import SwiftUI
import ReachuDesignSystem

public struct ContentView: View {
    public init() {}
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Reachu SDK Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Test your UI components here")
                    .foregroundColor(.secondary)
                
                // Test Design System Components
                VStack(spacing: 16) {
                    Text("Design System Test")
                        .font(.headline)
                    
                    // TODO: Testear RButton cuando esté implementado
                    Button("Test Button") {
                        print("Button tapped!")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // TODO: Testear RCard cuando esté implementado
                    VStack {
                        Text("Test Card")
                        Text("This will be a RCard component")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Navigation to different test screens
                VStack(spacing: 12) {
                    NavigationLink("Test Product Components") {
                        ProductTestView()
                    }
                    .buttonStyle(.bordered)
                    
                    NavigationLink("Test Cart Components") {
                        CartTestView()
                    }
                    .buttonStyle(.bordered)
                    
                    NavigationLink("Test Design System") {
                        DesignSystemTestView()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Reachu SDK")
        }
    }
}

#Preview {
    ContentView()
}
