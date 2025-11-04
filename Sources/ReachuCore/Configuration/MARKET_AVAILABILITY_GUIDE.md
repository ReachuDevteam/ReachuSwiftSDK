# 🌍 Market Availability Check - Reachu SDK

## Descripción

El SDK ahora verifica automáticamente si el mercado está disponible para el país del usuario antes de habilitar los componentes. Si el mercado no está disponible, todos los componentes de Reachu se ocultan automáticamente.

## Uso Básico

### Opción 1: Sin verificación de país (SDK siempre habilitado)

```swift
import ReachuCore

@main
struct MyApp: App {
    init() {
        ConfigurationLoader.loadConfiguration()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Opción 2: Con verificación de país del usuario

```swift
import ReachuCore

@main
struct MyApp: App {
    init() {
        // Pasar el país del usuario
        // El SDK verificará si el mercado está disponible para este país
        ConfigurationLoader.loadConfiguration(userCountryCode: "US")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Opción 3: Detectar país del usuario automáticamente

```swift
import ReachuCore
import CoreLocation

@main
struct MyApp: App {
    init() {
        // Detectar país del usuario desde el sistema
        let userCountry = Locale.current.region?.identifier ?? "US"
        ConfigurationLoader.loadConfiguration(userCountryCode: userCountry)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Opción 4: Usar variable de entorno

```swift
// En Xcode: Edit Scheme → Run → Arguments → Environment Variables
// Agregar: REACHU_USER_COUNTRY = US

ConfigurationLoader.loadConfiguration()
// Automáticamente lee REACHU_USER_COUNTRY si está configurada
```

## Comportamiento

### Si el mercado está disponible:
- ✅ SDK se habilita (`isMarketAvailable = true`)
- ✅ Todos los componentes de Reachu se muestran normalmente
- ✅ Los productos se cargan correctamente

### Si el mercado NO está disponible:
- ❌ SDK se deshabilita (`isMarketAvailable = false`)
- ❌ Todos los componentes de Reachu se ocultan automáticamente
- ❌ No se hacen llamadas a la API
- ⚠️ Solo se muestra un warning en los logs (no errores)

## Componentes que se Oculten Automáticamente

Cuando `isMarketAvailable = false`, estos componentes se ocultan automáticamente:

- ✅ `RProductSlider` - Se oculta completamente
- ✅ `RProductCard` - Se oculta (si usa datos del API)
- ✅ `RCheckoutOverlay` - Se oculta completamente
- ✅ `RFloatingCartIndicator` - Se oculta completamente
- ✅ `RProductDetailOverlay` - Se oculta completamente
- ✅ Cualquier otro componente que verifique `ReachuConfiguration.shared.shouldUseSDK`

## Verificación Manual

Puedes verificar manualmente si el SDK está disponible:

```swift
import ReachuCore

if ReachuConfiguration.shared.shouldUseSDK {
    // SDK está disponible, mostrar componentes
    RProductSlider(...)
} else {
    // SDK no disponible, ocultar o mostrar alternativa
    Text("Shopping not available in your region")
}
```

## Usar Helper View Wrapper

También puedes usar el wrapper helper para ocultar automáticamente:

```swift
import ReachuUI

ReachuComponentWrapper {
    // Todos estos componentes se ocultan si el mercado no está disponible
    RProductSlider(...)
    RFloatingCartIndicator()
}

// O usar el modifier
RProductSlider(...)
    .reachuOnly()
```

## Ejemplo Completo

```swift
import SwiftUI
import ReachuCore
import ReachuUI

@main
struct MyApp: App {
    init() {
        // Detectar país del usuario
        let userCountry = getUserCountry() // Tu función para detectar país
        
        // Cargar configuración con verificación de mercado
        ConfigurationLoader.loadConfiguration(userCountryCode: userCountry)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var cartManager = CartManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    // Tu contenido normal de la app
                    Text("My App Content")
                    
                    // Componentes de Reachu - se ocultan automáticamente si el mercado no está disponible
                    RProductSlider(
                        title: "Recommended Products",
                        layout: .cards,
                        currency: cartManager.currency,
                        country: cartManager.country
                    )
                    .environmentObject(cartManager)
                }
            }
        }
        .environmentObject(cartManager)
        .overlay {
            // Cart indicator también se oculta automáticamente
            RFloatingCartIndicator()
                .environmentObject(cartManager)
        }
        .sheet(isPresented: $cartManager.isCheckoutPresented) {
            // Checkout también se oculta automáticamente
            RCheckoutOverlay()
                .environmentObject(cartManager)
        }
    }
}

func getUserCountry() -> String {
    // Opción 1: Desde el sistema
    if let region = Locale.current.region?.identifier {
        return region
    }
    
    // Opción 2: Desde tu backend/API
    // let userProfile = await fetchUserProfile()
    // return userProfile.countryCode
    
    // Opción 3: Fallback
    return "US"
}
```

## Logs

Cuando el mercado no está disponible, verás:

```
🔍 [Config] Checking market availability for country: XX
⚠️ [Config] Market not available for XX - SDK disabled
⚠️ [ReachuSDK] Market not available for country: XX - SDK disabled
```

Cuando el mercado está disponible:

```
🔍 [Config] Checking market availability for country: US
✅ [Config] Market available for US - SDK enabled
✅ [ReachuSDK] Market available for country: US - SDK enabled
```

## Notas

- Si no pasas `userCountryCode`, el SDK se habilita por defecto (comportamiento anterior)
- La verificación es asíncrona y no bloquea la inicialización de la app
- Si hay un error de red durante la verificación, el SDK se habilita por defecto (para no bloquear el uso)
- Solo los errores 404/NOT_FOUND deshabilitan el SDK

