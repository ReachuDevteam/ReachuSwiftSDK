# TV2 Demo App

Demo app para TV2 con diseño inspirado en su aplicación oficial.

## 🎨 Estructura

```
tv2demo/
├── Theme/
│   └── TV2Theme.swift          # Colores, tipografía, espaciado
├── Models/
│   └── ContentModels.swift     # Modelos de datos (Category, ContentItem)
├── Components/
│   ├── CategoryChip.swift      # Chip de categoría
│   └── ContentCard.swift       # Card de contenido con imagen
├── Views/
│   └── HomeView.swift          # Vista principal
└── ContentView.swift           # Entry point
```

## 🎯 Features Implementadas

- ✅ Tema oscuro personalizado matching TV2
- ✅ Navegación por categorías horizontales
- ✅ Cards de contenido con badges (DIREKTE, fecha)
- ✅ Secciones scrollables horizontales
- ✅ UI responsive y moderna

## 🎨 Theme

### Colores
- **Background**: `#1A1625` (púrpura oscuro)
- **Surface**: `#2B2438` (púrpura medio)
- **Primary**: `#7B5FFF` (morado brillante)
- **Secondary**: `#E893CF` (rosa)
- **Accent**: `#00D9FF` (cyan)

### Categorías
- Sporten (Todos)
- Fotball
- Norsk
- Tennis
- Håndball
- Sykkel

## 🚀 Next Steps

1. **Integrar ReachuSDK** - Agregar livestream support
2. **Imágenes reales** - Usar AsyncImage con URLs reales
3. **Navegación** - Implementar detail views
4. **Productos** - Integrar sistema de productos en livestreams
5. **API** - Conectar con backend de TV2

## 📝 Notas

- App usa SwiftUI puro (CoreData removido)
- Diseño optimizado para iOS 15+
- Mock data para testing inicial


