# 📱 Reachu SDK Demo App

Una aplicación iOS nativa que demuestra cómo usar el Reachu Swift SDK.

## 🚀 Instalación y Uso

### Prerrequisitos
- Xcode 15.0+
- iOS 15.0+

### Configuración

1. **Abrir el proyecto en Xcode:**
   ```bash
   open Demo/ReachuDemoApp/ReachuDemoApp.xcodeproj
   ```

2. **Agregar dependencia del SDK:**
   - En Xcode, selecciona el proyecto "ReachuDemoApp"
   - Ve a "Package Dependencies" 
   - Click "+" → "Add Local..."
   - Selecciona la carpeta raíz: `/Users/angelo/ReachuSwiftSDK`
   - Selecciona "ReachuDesignSystem"
   - Click "Add Package"

3. **Compilar y ejecutar:**
   ```
   Cmd+B  # Compilar
   Cmd+R  # Ejecutar en simulador
   ```

## 🎯 Funcionalidades

### ✅ Implementado
- **Design System Demo**: Colores, tipografía, botones y spacing del SDK
- **Navegación principal**: Con 4 secciones demo
- **SwiftUI Previews**: Para desarrollo iterativo

### 🚧 Próximamente  
- **Product Catalog**: Catálogo de productos con filtros
- **Shopping Cart**: Carrito funcional completo
- **Checkout Flow**: Flujo de checkout 3-pasos

## 🛠️ Desarrollo

Esta demo app consume el SDK como lo haría cualquier desarrollador externo:

```swift
import ReachuDesignSystem

// Usar componentes del SDK
RButton(title: "Add to Cart", style: .primary) {
    // Acción
}

// Usar tokens de diseño
Text("Title")
    .font(ReachuTypography.headline)
    .foregroundColor(ReachuColors.primary)
```

## 📱 Preview en Tiempo Real

Los cambios en el SDK se reflejan automáticamente en:
- SwiftUI Previews
- Simulador (rebuild automático)
- Dispositivos físicos

¡Perfecta para desarrollo iterativo del SDK! 🎨✨
