# 🚀 Cómo Abrir ReachuDemoApp Correctamente

## ⚠️ Problema Común

Si ves este error:
```
Couldn't load ReachuSwiftSDK because it is already opened from another project or workspace
Missing package product 'ReachuUI'
```

**Causa:** Tienes otro proyecto abierto (como tv2demo) que también usa el SDK local.

## ✅ Solución

### Opción 1: Un Proyecto a la Vez (Recomendado)

**Antes de abrir ReachuDemoApp:**

1. **Cierra Xcode completamente**
2. **Abre SOLO este proyecto:**
   ```bash
   open ReachuDemoApp.xcodeproj
   ```

**Si ya tenías Xcode abierto:**
1. Cierra todos los proyectos (⌘W en cada ventana)
2. Abre solo ReachuDemoApp

### Opción 2: Usar un Workspace (Para trabajar con múltiples demos)

Si necesitas trabajar con ReachuDemoApp y tv2demo al mismo tiempo, crea un workspace:

**En la terminal:**
```bash
cd /Users/angelo/ReachuSwiftSDK/Demo
mkdir -p ReachuDemos.xcworkspace
```

**En Xcode:**
1. File → New → Workspace
2. Guarda como "ReachuDemos.xcworkspace" en `/Users/angelo/ReachuSwiftSDK/Demo/`
3. Arrastra ambos proyectos:
   - ReachuDemoApp/ReachuDemoApp.xcodeproj
   - tv2demo/tv2demo.xcodeproj
4. Cierra el workspace
5. Abre: `open /Users/angelo/ReachuSwiftSDK/Demo/ReachuDemos.xcworkspace`

Ahora ambos proyectos compartirán el SDK sin conflictos.

## 🔄 Si Sigues Viendo Errores de "Missing Package"

### Reset Package Caches

**Opción 1 - En Xcode:**
1. File → Packages → Reset Package Caches
2. Espera a que termine
3. File → Packages → Resolve Package Versions

**Opción 2 - En Terminal:**
```bash
# Limpia todos los caches
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf /Users/angelo/ReachuSwiftSDK/Demo/ReachuDemoApp/.build

# Abre el proyecto
open /Users/angelo/ReachuSwiftSDK/Demo/ReachuDemoApp/ReachuDemoApp.xcodeproj
```

### Verifica la Ruta del Paquete

En Xcode:
1. Project Navigator → ReachuDemoApp (project)
2. Package Dependencies tab
3. Deberías ver "ReachuSwiftSDK" con path: `../../`
4. Si no, elimina y vuelve a agregar:
   - Click "-" para remover
   - Click "+" → Add Local...
   - Navega a `/Users/angelo/ReachuSwiftSDK` (raíz del repo)
   - Selecciona la carpeta
   - Add Package

## 📦 Productos del SDK Disponibles

Una vez resuelto, deberías poder importar:

```swift
import ReachuCore
import ReachuUI
import ReachuDesignSystem
import ReachuLiveShow
import ReachuLiveUI
```

## 🐛 Troubleshooting

### "The package product 'X' is not available"

**Causa:** El Package.swift no exporta ese producto o hay un error de sintaxis.

**Solución:**
```bash
cd /Users/angelo/ReachuSwiftSDK
swift package resolve
```

Si hay errores, los verás aquí.

### "Dependency cycle detected"

**Causa:** Hay referencias circulares entre targets.

**Solución:** 
Revisa `Package.swift` para asegurar que no haya ciclos:
- ReachuCore no debería depender de ReachuUI
- ReachuUI puede depender de ReachuCore
- etc.

### Build falla con "No such module"

**Causa:** El módulo no se está compilando.

**Solución:**
1. Product → Clean Build Folder (⌘⇧K)
2. Cierra Xcode
3. Borra derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```
4. Abre el proyecto de nuevo

## 📝 Best Practices

1. **Siempre cierra otros proyectos** antes de abrir uno nuevo que use el mismo SDK local
2. **Usa un workspace** si necesitas trabajar con múltiples demos
3. **Resuelve packages** después de cambiar algo en Package.swift
4. **Limpia derived data** si ves comportamiento extraño

## 🎯 Quick Commands

```bash
# Limpiar todo y abrir el proyecto
rm -rf ~/Library/Developer/Xcode/DerivedData/ReachuDemoApp-*
open /Users/angelo/ReachuSwiftSDK/Demo/ReachuDemoApp/ReachuDemoApp.xcodeproj

# Ver qué proyecto tiene el SDK abierto
lsof | grep ReachuSwiftSDK | grep Xcode

# Matar todos los procesos de Xcode (¡usa con cuidado!)
# killall Xcode
```

