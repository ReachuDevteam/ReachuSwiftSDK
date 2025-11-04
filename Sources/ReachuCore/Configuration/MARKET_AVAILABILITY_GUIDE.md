# 🌍 Market Availability Check - Reachu SDK

## Description

The SDK automatically checks if the market is available for the user’s country before enabling components. If the market is not available, all Reachu components are hidden automatically.

## Basic Usage

### Option 1: Without country check (SDK always enabled)

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

### Option 2: With user country check

```swift
import ReachuCore

@main
struct MyApp: App {
    init() {
        // Pass user country code
        // The SDK will check market availability for this country
        ConfigurationLoader.loadConfiguration(userCountryCode: "US")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Option 3: Auto-detect user country

```swift
import ReachuCore
import CoreLocation

@main
struct MyApp: App {
    init() {
        // Detect user country from system locale
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

### Option 4: Use environment variable

```swift
// In Xcode: Edit Scheme → Run → Arguments → Environment Variables
// Add: REACHU_USER_COUNTRY = US

ConfigurationLoader.loadConfiguration()
// Automatically reads REACHU_USER_COUNTRY if set
```

## Behavior

### If the market is available:
- ✅ SDK enables (`isMarketAvailable = true`)
- ✅ All Reachu components render normally
- ✅ Products load as expected

### If the market is NOT available:
- ❌ SDK disables (`isMarketAvailable = false`)
- ❌ All Reachu components are hidden automatically
- ❌ No API calls are made
- ⚠️ Only a warning is logged (no errors)

## Components Hidden Automatically

When `isMarketAvailable = false`, these components hide automatically:

- ✅ `RProductSlider` - Se oculta completamente
- ✅ `RProductCard` - Se oculta (si usa datos del API)
- ✅ `RCheckoutOverlay` - Se oculta completamente
- ✅ `RFloatingCartIndicator` - Se oculta completamente
- ✅ `RProductDetailOverlay` - Se oculta completamente
- ✅ Cualquier otro componente que verifique `ReachuConfiguration.shared.shouldUseSDK`

## Manual Check

You can manually check if the SDK is available:

```swift
import ReachuCore

if ReachuConfiguration.shared.shouldUseSDK {
    // SDK available — show components
    RProductSlider(...)
} else {
    // SDK not available — hide or show fallback
    Text("Shopping not available in your region")
}
```

## Helper View Wrapper

You can also use the helper wrapper to hide automatically:

```swift
import ReachuUI

ReachuComponentWrapper {
    // All these components hide if market is not available
    RProductSlider(...)
    RFloatingCartIndicator()
}

// Or use the modifier
RProductSlider(...)
    .reachuOnly()
```

## Complete Example

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
    
    // Option 2: From your backend/API
    // let userProfile = await fetchUserProfile()
    // return userProfile.countryCode
    
    // Option 3: Fallback
    return "US"
}
```

## Logs

When the market is not available, you’ll see:

```
🔍 [Config] Checking market availability for country: XX
⚠️ [Config] Market not available for XX - SDK disabled
⚠️ [ReachuSDK] Market not available for country: XX - SDK disabled
```

When the market is available:

```
🔍 [Config] Checking market availability for country: US
✅ [Config] Market available for US - SDK enabled
✅ [ReachuSDK] Market available for country: US - SDK enabled
```

## Notes

- If you don’t pass `userCountryCode`, the SDK enables by default (previous behavior)
- The check is asynchronous and does not block app initialization
- If a network error occurs during the check, the SDK enables by default (to avoid blocking usage)
- Only 404/NOT_FOUND disables the SDK
