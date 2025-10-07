# 🚀 Reachu Workspace Guide

## ¿Qué es el Workspace?

`ReachuWorkspace.xcworkspace` es un contenedor que agrupa:
- 📦 **ReachuSwiftSDK** (Package.swift) - El SDK principal
- 📱 **tv2demo** - Demo app para TV2
- 📱 **ReachuDemoApp** - Demo app oficial del SDK

## ✅ Ventajas del Workspace

1. **Todos los proyectos abiertos simultáneamente** - Sin conflictos de paquetes
2. **Navegación rápida** - Cambiar entre proyectos con ⌘1, ⌘2, ⌘3
3. **Debugging unificado** - Ver código del SDK mientras debuggeas las apps
4. **Búsqueda global** - ⇧⌘F busca en todos los proyectos
5. **Compilación inteligente** - Xcode sabe qué recompilar

## 🎯 Cómo usar

### Abrir el Workspace:

```bash
# Opción 1: Desde terminal
open /Users/angelo/ReachuSwiftSDK/ReachuWorkspace.xcworkspace

# Opción 2: Alias (agregar a ~/.zshrc)
alias rwork="open /Users/angelo/ReachuSwiftSDK/ReachuWorkspace.xcworkspace"
```

### Seleccionar qué compilar:

1. En Xcode, arriba a la izquierda verás el **Scheme Selector**
2. Haz clic y elige:
   - `tv2demo` → Para trabajar en tv2demo
   - `ReachuDemoApp` → Para trabajar en ReachuDemoApp
   - `ReachuUI`, `ReachuCore`, etc. → Para trabajar en el SDK

### Estructura en Xcode:

```
ReachuWorkspace
├── 📦 Package.swift (ReachuSwiftSDK)
│   ├── Sources/
│   │   ├── ReachuCore/
│   │   ├── ReachuUI/
│   │   ├── ReachuLiveShow/
│   │   └── ReachuLiveUI/
│   └── Tests/
├── 📱 tv2demo
│   ├── tv2demo/
│   └── Configuration/
├── 📱 ReachuDemoApp
│   ├── ReachuDemoApp/
│   └── Configuration/
└── 📄 README.md
```

## 🔧 Comandos útiles

### Limpiar todo el workspace:
```bash
cd /Users/angelo/ReachuSwiftSDK
rm -rf ~/Library/Developer/Xcode/DerivedData/ReachuWorkspace-*
rm -rf Demo/tv2demo/.swiftpm
rm -rf Demo/ReachuDemoApp/.swiftpm
```

### Resolver dependencias:
```bash
cd /Users/angelo/ReachuSwiftSDK
xcodebuild -resolvePackageDependencies -workspace ReachuWorkspace.xcworkspace -scheme tv2demo
```

### Compilar desde terminal:
```bash
# tv2demo
xcodebuild -workspace ReachuWorkspace.xcworkspace -scheme tv2demo -destination 'platform=iOS Simulator,name=iPhone 17' build

# ReachuDemoApp
xcodebuild -workspace ReachuWorkspace.xcworkspace -scheme ReachuDemoApp -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## 💡 Tips

### 1. Atajos de teclado útiles:
- `⌘1` → Project Navigator (cambiar entre proyectos)
- `⌘⇧O` → Open Quickly (buscar archivos en todo el workspace)
- `⌘⇧F` → Find in Workspace (buscar texto en todos los proyectos)
- `⌘⇧J` → Reveal in Project Navigator (mostrar archivo actual)

### 2. Debugging multi-proyecto:
- Puedes poner breakpoints en el SDK y en las apps al mismo tiempo
- Xcode te llevará automáticamente al código del SDK cuando lo necesites

### 3. Editar el SDK y ver cambios inmediatos:
- Edita código en `Sources/ReachuUI/`
- Compila `tv2demo` o `ReachuDemoApp`
- Los cambios se reflejan inmediatamente (no necesitas reinstalar el paquete)

## ⚠️ Importante

**SIEMPRE abre el `.xcworkspace`, NO los `.xcodeproj` individuales**

❌ MAL:
```bash
open Demo/tv2demo/tv2demo.xcodeproj  # NO HACER ESTO
```

✅ BIEN:
```bash
open ReachuWorkspace.xcworkspace  # SIEMPRE ESTO
```

## 🆘 Solución de problemas

### "Missing package product"
```bash
# Cerrar Xcode y limpiar
killall Xcode
rm -rf ~/Library/Developer/Xcode/DerivedData/ReachuWorkspace-*
open ReachuWorkspace.xcworkspace
```

### "Cannot find module"
1. File → Packages → Reset Package Caches
2. Product → Clean Build Folder (⇧⌘K)
3. Product → Build (⌘B)

### Schemes no aparecen
1. Product → Scheme → Manage Schemes...
2. Asegúrate que "Show" esté marcado para todos los schemes

## 🎉 ¡Listo!

Ahora puedes trabajar con ambas apps y el SDK simultáneamente sin problemas.
