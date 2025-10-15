# ContentCard Match Update

## Cambios Realizados

Se ha actualizado el componente `ContentCard` para soportar partidos de fútbol con logos de equipos, manteniendo la compatibilidad con el contenido regular.

### 1. Modelo ContentItem Extendido

Agregadas propiedades opcionales en `ContentModels.swift`:

```swift
let homeTeamLogo: String?      // Logo del equipo local
let awayTeamLogo: String?      // Logo del equipo visitante
let matchTime: String?         // Hora del partido (ej: "18:40")
let matchday: String?          // Día del partido (ej: "M")
```

### 2. ContentCard Mejorado

El componente ahora detecta automáticamente si es una card de partido (cuando tiene ambos logos) y aplica un diseño especial:

#### Diseño de Partido:
- **Gradientes multicapa**: Colores TV2 con efectos de profundidad
- **Header informativo**: Tiempo, ícono de deporte y día del partido
- **Logos de equipos**: Círculos blancos (70x70) con sombras
- **Tipografía especial**: Título más grande y subtítulo con bullets

#### Diseño Regular:
- Se mantiene el diseño original para contenido que no es partido

### 3. Mock Data

Se agregó un partido de ejemplo en `ContentModels.swift`:

```swift
ContentItem(
    title: "Barcelona - Olympiakos",
    subtitle: "Fotball • Menn • UEFA Champions League",
    imageURL: "barcelona_psg_bg",
    category: "Fotball",
    isLive: false,
    date: "Tir. 18:40",
    homeTeamLogo: "barcelona_logo",
    awayTeamLogo: "psg_logo",
    matchTime: "18:40",
    matchday: "M"
)
```

### 4. Ajustes en HomeView

Todas las cards mantienen el mismo tamaño:
- Todas las cards: 280x160 (uniforme)

## Características del Diseño

### Gradientes
1. **Base**: `#2B2438` → `#1A1625`
2. **Accent overlay**: Primary (20%) + Secondary (15%)

### Header Badges
- **Tiempo**: Badge azul con "Tir. HH:MM" (9/11pt)
- **Deporte**: Círculo con ícono de persona corriendo (24x24)
- **Matchday**: Badge translúcido con letra del día (11pt)
- **Padding**: 8px horizontal, 4px vertical
- **Corner radius**: 4pt

### Logos
- **Tamaño**: 60x60 círculos blancos
- **Logos internos**: 44x44
- **Spacing**: 30pt entre logos
- **Sombra**: `black.opacity(0.3)`, radius 8

### Typography
- **Título**: 16pt bold para partidos, caption para regular
- **Subtítulo**: 11pt medium con bullets separados (spacing 4pt)

## Uso

### Crear una Card de Partido

```swift
ContentItem(
    title: "Equipo A - Equipo B",
    subtitle: "Competición • Categoría • Liga",
    imageURL: "background_image",
    category: "Fotball",
    homeTeamLogo: "team_a_logo",    // Activa el modo partido
    awayTeamLogo: "team_b_logo",    // Activa el modo partido
    matchTime: "20:00",
    matchday: "M"
)
```

### Crear una Card Regular

```swift
ContentItem(
    title: "PROGRAMA DEPORTIVO",
    subtitle: "Descripción del contenido",
    imageURL: "background_image",
    category: "Deportes",
    isLive: true
    // No incluir homeTeamLogo ni awayTeamLogo
)
```

## Assets Requeridos

Para partidos, necesitas:
- Logos de equipos en `Assets.xcassets` (SVG recomendado)
- Imagen de fondo opcional
- Los logos deben tener fondo transparente

## Compatibilidad

✅ Retrocompatible con ContentCards existentes
✅ Detección automática de tipo de card
✅ Responsive a diferentes tamaños
✅ Usa el theme TV2 existente

## Testing

Para probar la card de partido:
1. Abre el proyecto en Xcode
2. La card aparecerá en la sección "Nylig" (ya que `isLive: false`)
3. Verifica que los logos se muestren correctamente
4. Verifica los gradientes y badges del header

