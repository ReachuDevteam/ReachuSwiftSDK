# Reachu SDK Demo App

Esta aplicación demo te permite desarrollar y testear los componentes UI del Reachu SDK en tiempo real.

## 🚀 Cómo usar durante desarrollo

### 1. Abrir en Xcode
```bash
cd Demo/ReachuSDKDemo
open Package.swift
```

### 2. Ejecutar la Demo App
- Selecciona el target `ReachuSDKDemo`
- Elige tu simulador (iPhone o iPad)
- Presiona `Cmd + R` para ejecutar

### 3. Desarrollo iterativo

La demo app hace referencia local al SDK (`../../`), por lo que cualquier cambio que hagas en:
- `Sources/ReachuDesignSystem/`
- `Sources/ReachuUI/`
- `Sources/ReachuCore/`

Se reflejará automáticamente cuando recompiles la demo app.

## 📱 Estructura de testing

### Design System Test
- Prueba colores, tipografía, espaciado
- Ve cómo se ven los tokens en pantalla
- Testea componentes base como `RButton`

### Product Components Test
- Desarrolla y prueba `ProductCardView`
- Testea `ProductListView` con datos mock
- Prueba `ProductDetailView`

### Cart Components Test
- Desarrolla `CartView`
- Testea `CartItemView`
- Prueba `MiniCartView`

## 🔄 Workflow recomendado

1. **Desarrolla el componente** en `Sources/ReachuUI/Views/`
2. **Añádelo a la demo** en `Demo/ReachuSDKDemo/Sources/ReachuSDKDemo/main.swift`
3. **Ejecuta la demo** para ver el resultado
4. **Itera** hasta que esté perfecto
5. **Commit** cuando esté listo

## 🎨 Testing de Design System

La demo incluye una sección específica para testear:
- Paleta de colores
- Escalas tipográficas  
- Sistema de espaciado
- Componentes base

## 📝 Notas

- Los componentes usan **SwiftUI Previews** para desarrollo rápido
- La demo app permite testing en **contexto real**
- Puedes testear **navegación** entre pantallas
- Testea tanto en **iPhone como iPad**
