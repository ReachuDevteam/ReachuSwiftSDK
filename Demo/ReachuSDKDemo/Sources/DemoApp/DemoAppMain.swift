import SwiftUI
import DemoAppLib

// Entry point para el executable - usando las vistas de DemoAppLib
@main
struct DemoAppMain: App {
    var body: some Scene {
        // Reutilizamos la configuración de DemoAppLib
        DemoAppContent().body
    }
}
