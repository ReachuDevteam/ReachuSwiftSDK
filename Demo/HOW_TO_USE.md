# 🎯 Cómo usar la Demo App

La Demo App es un **target opcional** que puedes usar para desarrollar y testear componentes del SDK sin incluirla en tu aplicación final.

## 🚀 Opción 1: Desarrollo directo del SDK

### Para desarrolladores del SDK:
```bash
# Clonar el repositorio
git clone https://github.com/angelosv/ReachuSwiftSDK.git
cd ReachuSwiftSDK

# Abrir la demo app
cd Demo/ReachuSDKDemo
open Package.swift
```

### En Xcode:
1. Selecciona el target `ReachuSDKDemo`
2. Elige tu simulador
3. Presiona `Cmd + R`

## 📱 Opción 2: Desde tu proyecto iOS

### Si quieres testear componentes en tu app:
```swift
// En tu Package.swift
dependencies: [
    .package(url: "https://github.com/angelosv/ReachuSwiftSDK.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "ReachuCore", package: "ReachuSwiftSDK"),
            .product(name: "ReachuUI", package: "ReachuSwiftSDK"),
            // Solo si quieres la demo:
            .product(name: "ReachuSDKDemo", package: "ReachuSwiftSDK"),
        ]
    ),
]
```

## 🎨 Qué incluye la Demo App

### ✅ Design System Testing
- Paleta de colores
- Tipografía y escalas
- Sistema de espaciado
- Componentes base (RButton, RCard, etc.)

### ✅ Component Testing
- Product components (ProductCardView, ProductListView)
- Cart components (CartView, CartItemView)
- Checkout components
- LiveStream components

### ✅ Desarrollo iterativo
- Cambios en tiempo real
- SwiftUI Previews
- Testing en contexto real

## 📝 Workflow de desarrollo

1. **Desarrolla** un componente en `Sources/ReachuUI/`
2. **Añádelo** a la demo app para testing
3. **Ejecuta** la demo para ver el resultado
4. **Itera** hasta que esté perfecto
5. **Commit** cuando esté listo

## 🔍 Importante

- **La demo NO se incluye** en aplicaciones que usen el SDK
- **Es solo para desarrollo** y testing
- **Completamente opcional** - solo se carga si la solicitas
- **No afecta el tamaño** de tu aplicación final

## 🎯 Casos de uso

### Para developers del SDK:
- Testing rápido de nuevos componentes
- Debugging de issues
- QA de funcionalidades

### Para usuarios del SDK:
- Ver ejemplos de implementación
- Testear integraciones
- Reference implementations
