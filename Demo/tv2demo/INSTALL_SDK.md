# Instalar ReachuSDK en tv2demo

## Método 1: Dependencia Local (Recomendado para desarrollo)

### Pasos en Xcode:

1. **Abrir el proyecto tv2demo**
   ```bash
   open tv2demo.xcodeproj
   ```

2. **Agregar Paquete Local:**
   - Click en el proyecto `tv2demo` en el navegador
   - Selecciona el target `tv2demo`
   - Ve a la pestaña **"General"**
   - Scroll hasta **"Frameworks, Libraries, and Embedded Content"**
   - Click en el botón **"+"**
   - Click en **"Add Other..."** → **"Add Package Dependency..."**
   - Click en **"Add Local..."**
   - Navega a: `/Users/angelo/ReachuSwiftSDK`
   - Selecciona la carpeta raíz del SDK
   - Click **"Add Package"**

3. **Seleccionar Productos:**
   Marca los módulos que necesitas:
   - ✅ `ReachuCore` (requerido)
   - ✅ `ReachuDesignSystem` (requerido)
   - ✅ `ReachuUI` (requerido)
   - ✅ `ReachuLiveUI` (para livestreaming)
   - ✅ `ReachuLiveShow` (para livestreaming)

4. **Build**
   - ⌘B para compilar
   - Debería compilar sin errores

---

## Método 2: Terminal (Rápido)

Ejecuta este comando desde la carpeta del proyecto:

```bash
cd /Users/angelo/ReachuSwiftSDK/Demo/tv2demo

# Esto abrirá Xcode con el proyecto
xed tv2demo.xcodeproj
```

Luego sigue los pasos del Método 1.

---

## Verificar Instalación

En cualquier archivo Swift (por ejemplo, `ContentView.swift`):

```swift
import ReachuCore
import ReachuDesignSystem
import ReachuUI
import ReachuLiveUI

struct ContentView: View {
    var body: some View {
        Text("SDK instalado correctamente")
    }
}
```

Si no hay errores de compilación, ¡está instalado! ✅

---

## Usar el SDK

### Ejemplo básico:

```swift
import SwiftUI
import ReachuUI
import ReachuCore

struct ProductView: View {
    let product = Product(
        id: 1,
        title: "Product",
        price: Price(amount: 99.99, currency_code: "USD")
    )
    
    var body: some View {
        RProductCard(product: product)
    }
}
```

### LiveShow:

```swift
import ReachuLiveUI
import ReachuLiveShow

struct LiveView: View {
    @StateObject var liveShowManager = LiveShowManager.shared
    
    var body: some View {
        if let stream = liveShowManager.activeStream {
            RLiveShowFullScreenOverlay(stream: stream)
        }
    }
}
```

---

## Troubleshooting

### Error: "No such module 'ReachuCore'"

**Solución:**
1. Asegúrate de haber agregado el paquete local
2. Clean build folder: ⇧⌘K
3. Rebuild: ⌘B

### Error: "Cannot find 'Product' in scope"

**Solución:**
Importa el módulo correcto:
```swift
import ReachuCore  // Para Product, Cart, etc.
```

### Build muy lento

**Solución:**
La primera vez el build será lento porque compila todo el SDK.
Los builds subsecuentes serán más rápidos gracias al cache.

---

## Próximos Pasos

Una vez instalado el SDK:

1. ✅ Reemplazar mock data con datos del SDK
2. ✅ Integrar RLiveShowFullScreenOverlay
3. ✅ Agregar RProductCard a las vistas
4. ✅ Implementar checkout con RCheckoutOverlay
5. ✅ Configurar theme personalizado de TV2

---

**Documentación completa:** `/Users/angelo/ReachuSwiftSDK/README.md`

