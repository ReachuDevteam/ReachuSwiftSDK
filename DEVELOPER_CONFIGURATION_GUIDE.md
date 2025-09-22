# Developer Guide: Reachu SDK Configuration System

## 🎯 **¿Qué es el Sistema de Configuración?**

El sistema de configuración centralizado de Reachu SDK permite configurar **una sola vez** todos los aspectos del SDK (API key, colores, posición del cart, configuraciones de red, etc.) y que **todos los módulos** (Core, UI, LiveShow) funcionen automáticamente sin configuración adicional.

### **Problema que Resuelve**
Antes necesitabas configurar cada módulo por separado:
```swift
// ❌ Antes: Configuración repetitiva
ReachuCore.configure(apiKey: "key")
ReachuUI.configure(theme: .custom, cartPosition: .bottomRight)
LiveShow.configure(apiKey: "key", chatEnabled: true)
ProductCard.configure(colors: customColors)
```

Ahora es súper simple:
```swift
// ✅ Ahora: Una configuración para todo
ReachuConfiguration.configure(apiKey: "your-key")
// Todo funciona automáticamente 🎉
```

## 📁 **Archivos del Sistema de Configuración**

### **1. `ReachuConfiguration.swift`** - Configuración Principal
**Qué hace:** Es el cerebro del sistema. Maneja la configuración global del SDK.

**Componentes principales:**
- `ReachuConfiguration` - Singleton que guarda toda la configuración
- `ReachuEnvironment` - Enum para sandbox/production  
- `ConfigurationError` - Errores de configuración

**Cuándo usarlo:** Para configurar el SDK inicialmente o cambiar configuraciones en runtime.

```swift
// Configuración básica
ReachuConfiguration.configure(apiKey: "tu-key")

// Configuración avanzada
ReachuConfiguration.configure(
    apiKey: "tu-key",
    environment: .production,
    theme: .dark,
    cartConfig: CartConfiguration(floatingCartPosition: .bottomRight)
)
```

### **2. `ReachuTheme.swift`** - Sistema de Temas
**Qué hace:** Define todos los aspectos visuales del SDK (colores, tipografías, espaciados).

**Componentes principales:**
- `ReachuTheme` - Contenedor del tema completo
- `ColorScheme` - Paleta de colores (primary, secondary, success, error, etc.)
- `TypographyScheme` - Tipos de letra (títulos, body, captions)
- `SpacingScheme` - Espaciados estándar (xs, sm, md, lg, xl)
- `BorderRadiusScheme` - Radios de bordes

**Cuándo usarlo:** Para personalizar la apariencia visual del SDK.

```swift
// Tema predefinido
ReachuConfiguration.configure(
    apiKey: "key",
    theme: .dark  // .default, .light, .dark, .minimal
)

// Tema personalizado
let customTheme = ReachuTheme(
    name: "Mi Marca",
    colors: ColorScheme(
        primary: Color.blue,
        secondary: Color.purple
    )
)
ReachuConfiguration.configure(apiKey: "key", theme: customTheme)
```

### **3. `ModuleConfigurations.swift`** - Configuraciones Específicas
**Qué hace:** Define configuraciones específicas para cada módulo del SDK.

**Configuraciones incluidas:**

#### **`CartConfiguration`** - Comportamiento del Carrito
```swift
CartConfiguration(
    floatingCartPosition: .bottomRight,     // Posición del cart flotante
    floatingCartDisplayMode: .full,         // Modo de visualización
    floatingCartSize: .medium,              // Tamaño
    autoSaveCart: true,                     // Auto-guardar en dispositivo
    showCartNotifications: true,            // Mostrar notificaciones
    enableGuestCheckout: true,              // Permitir checkout sin cuenta
    supportedPaymentMethods: ["stripe", "klarna"]
)
```

#### **`UIConfiguration`** - Configuración de Interfaz
```swift
UIConfiguration(
    enableProductCardAnimations: true,      // Animaciones en cards
    showProductBrands: true,                // Mostrar marcas
    enableHapticFeedback: true,             // Feedback táctil
    imageQuality: .medium,                  // Calidad de imágenes
    defaultProductCardVariant: .grid        // Estilo por defecto
)
```

#### **`NetworkConfiguration`** - Configuración de Red
```swift
NetworkConfiguration(
    timeout: 30.0,                          // Timeout de requests
    retryAttempts: 3,                       // Intentos de retry
    enableCaching: true,                    // Cache habilitado
    enableLogging: false                    // Logging de red
)
```

#### **`LiveShowConfiguration`** - Configuración de LiveShow
```swift
LiveShowConfiguration(
    autoJoinChat: true,                     // Auto-unirse al chat
    enableShoppingDuringStream: true,       // Shopping durante stream
    videoQuality: .auto,                    // Calidad de video
    enableAutoplay: false                   // Auto-reproducción
)
```

### **4. `ConfigurationLoader.swift`** - Cargador de Configuraciones
**Qué hace:** Permite cargar configuraciones desde diferentes fuentes (JSON, Plist, variables de entorno, URLs remotas).

**Métodos principales:**
- `loadFromJSON()` - Carga desde archivo JSON
- `loadFromPlist()` - Carga desde archivo Plist
- `loadFromEnvironment()` - Carga desde variables de entorno
- `loadFromRemote()` - Carga desde URL remota

**Cuándo usarlo:** Cuando quieres externalizar la configuración del código.

```swift
// Desde archivo JSON
try ConfigurationLoader.loadFromJSON(fileName: "reachu-config")

// Desde variables de entorno (CI/CD)
ConfigurationLoader.loadFromEnvironment()

// Desde URL remota
await ConfigurationLoader.loadFromRemote(url: configURL)
```

## 🚀 **Cómo Usar el Sistema**

### **Paso 1: Configuración Inicial**
Elige una de estas opciones según tu caso de uso:

#### **Opción A: Configuración Simple (Recomendada para empezar)**
```swift
// En AppDelegate o App.swift
ReachuConfiguration.configure(apiKey: "tu-reachu-api-key")
```

#### **Opción B: Configuración Personalizada**
```swift
ReachuConfiguration.configure(
    apiKey: "tu-reachu-api-key",
    environment: .production,
    theme: .dark,
    cartConfig: CartConfiguration(
        floatingCartPosition: .bottomRight,
        showCartNotifications: true
    ),
    uiConfig: UIConfiguration(
        enableAnimations: true,
        showProductBrands: true
    )
)
```

#### **Opción C: Configuración desde Archivo JSON**
```swift
do {
    try ConfigurationLoader.loadFromJSON(fileName: "reachu-config")
} catch {
    // Fallback a configuración manual
    ReachuConfiguration.configure(apiKey: "tu-api-key")
}
```

### **Paso 2: Usar los Componentes**
Después de la configuración inicial, todos los componentes funcionan automáticamente:

```swift
import ReachuUI

struct ContentView: View {
    var body: some View {
        VStack {
            // Todos usan la configuración global automáticamente
            RProductCard(product: producto)
            RProductSlider(products: productos)
            RFloatingCartIndicator()  // Posición configurada globalmente
        }
        .sheet(isPresented: $showCheckout) {
            RCheckoutOverlay()        // Tema y configuración globales
        }
    }
}
```

### **Paso 3: Cambios en Runtime (Opcional)**
```swift
// Cambiar tema dinámicamente
ReachuConfiguration.updateTheme(.light)

// Cambiar configuración del cart
ReachuConfiguration.updateCartConfiguration(
    CartConfiguration(floatingCartPosition: .topRight)
)
```

## 🔧 **Casos de Uso Comunes**

### **Desarrollo Multi-Ambiente**
```swift
#if DEBUG
ReachuConfiguration.configure(
    apiKey: "sandbox-key",
    environment: .sandbox,
    networkConfig: NetworkConfiguration(enableLogging: true)
)
#else
ReachuConfiguration.configure(
    apiKey: "production-key",
    environment: .production
)
#endif
```

### **White-Label / Multi-Marca**
```swift
let brandTheme = ReachuTheme(
    name: "Mi Marca",
    colors: ColorScheme(
        primary: Color(red: 0.2, green: 0.4, blue: 0.8),
        secondary: Color(red: 0.8, green: 0.2, blue: 0.4)
    )
)

ReachuConfiguration.configure(
    apiKey: "key",
    theme: brandTheme
)
```

### **Configuración Externa (JSON)**
Crea `reachu-config.json` en tu bundle:
```json
{
  "apiKey": "tu-api-key",
  "environment": "production",
  "theme": {
    "name": "Brand Theme",
    "colors": {
      "primary": "#007AFF",
      "secondary": "#5856D6"
    }
  },
  "cart": {
    "floatingCartPosition": "bottomRight",
    "showCartNotifications": true
  }
}
```

### **CI/CD con Variables de Entorno**
```bash
# Variables de entorno
export REACHU_API_KEY="production-key"
export REACHU_ENVIRONMENT="production"
```

```swift
// En tu app
ConfigurationLoader.loadFromEnvironment()
```

## ✅ **Beneficios del Sistema**

### **Para Desarrolladores:**
- ✅ **Setup una vez** → Todo funciona
- ✅ **Menos código** → Sin configuración repetitiva
- ✅ **Type-safe** → Errores en compile-time
- ✅ **Flexible** → Múltiples formas de configurar
- ✅ **Testeable** → Fácil cambiar configs para tests

### **Para Equipos:**
- ✅ **Consistencia** → Mismo tema en toda la app
- ✅ **Mantenible** → Cambios centralizados
- ✅ **Escalable** → Fácil añadir nuevas configuraciones
- ✅ **Multi-ambiente** → Dev/Staging/Production

### **Para Empresas:**
- ✅ **White-label ready** → Personalización completa
- ✅ **Configuración remota** → Updates sin deploy
- ✅ **Compliance** → Control total de configuraciones
- ✅ **CI/CD friendly** → Variables de entorno

## 🎯 **Resumen**

El sistema de configuración de Reachu SDK es como el **centro de control** de tu integración ecommerce:

1. **Configuras una vez** → Todo funciona
2. **Personalizas fácilmente** → Temas, colores, comportamiento
3. **Escalas sin problemas** → Multi-ambiente, white-label
4. **Mantienes con facilidad** → Configuración centralizada

¡Es la base que hace que el SDK sea verdaderamente **plug-and-play**! 🚀
