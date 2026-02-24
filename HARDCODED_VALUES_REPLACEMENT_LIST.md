# Lista de Valores Hardcodeados a Reemplazar

Este documento lista todos los valores hardcodeados encontrados en los componentes del engagement system y sus reemplazos correspondientes usando la configuración del SDK.

## Colores Hardcodeados

### Reemplazos Completados

| Hardcodeado Original | Reemplazo SDK | Ubicación |
|---------------------|---------------|-----------|
| `ViaplayTheme.Colors.pink` | `VioColors.primary` | Todos los componentes |
| `ViaplayTheme.Colors.pink.opacity(0.6)` | `VioColors.primary.opacity(0.6)` | PollCard, ContestCard |
| `ViaplayTheme.Colors.pink.opacity(0.8)` | `VioColors.primary.opacity(0.8)` | Botones, ContestCard |
| `Color.white` | `VioColors.textPrimary` | Textos principales |
| `Color.white.opacity(0.3)` | `VioColors.textPrimary.opacity(0.3)` | Drag indicators |
| `Color.white.opacity(0.7)` | `VioColors.textSecondary` | Textos secundarios |
| `Color.white.opacity(0.8)` | `VioColors.textSecondary.opacity(0.8)` | Textos secundarios |
| `Color.white.opacity(0.95)` | `VioColors.textPrimary` | Textos principales |
| `Color.black.opacity(0.4)` | `VioColors.surface.opacity(0.4)` | Backgrounds de cards |
| `Color(hex: "3A3D5C")` | `VioColors.surfaceSecondary` | Botones de opciones |
| `Color(hex: "120019")` | `VioColors.background` | Backgrounds |
| `Color.green` | `VioColors.success` | Indicadores de éxito |
| `Color.red.opacity(0.8)` | `VioColors.error.opacity(0.8)` | Botones de error |
| `Color.white.opacity(0.15)` | `VioColors.surfaceSecondary.opacity(0.5)` | Input fields |
| `Color.white.opacity(0.2)` | `VioColors.textPrimary.opacity(0.2)` | Progress bar backgrounds |

### Componentes Específicos

#### REngagementPollCard
- ✅ Botones de opciones seleccionadas: `VioColors.primary.opacity(0.6)`
- ✅ Botones de opciones no seleccionadas: `VioColors.surfaceSecondary`
- ✅ Barras de resultados: `VioColors.primary` para fill
- ✅ Texto "Takk for at du stemte!": `VioColors.primary`
- ✅ Gradientes de avatar: `VioColors.primary` con opacidades
- ✅ Drag indicator: `VioColors.textPrimary.opacity(0.3)`
- ✅ Background card: `VioColors.surface.opacity(0.4)`

#### REngagementContestCard
- ✅ Botón "Bli med!": `VioColors.primary.opacity(0.8)`
- ✅ Texto de premio: `VioColors.primary`
- ✅ Rueda de premios: `VioColors.primary` con opacidades alternadas
- ✅ Indicador "Du er med!": `VioColors.success`
- ✅ ProgressView tint: `VioColors.primary`
- ✅ Background de premio: `VioColors.surfaceSecondary.opacity(0.5)`

#### REngagementProductCard
- ✅ Precio: `VioColors.priceColor` (ya configurado en theme)
- ✅ Botón "Legg til": `VioColors.primary.opacity(0.8)`
- ✅ Badge de descuento: `VioColors.primary`
- ✅ Checkmark cuando agregado: `VioColors.success`
- ✅ Placeholder de imagen: `VioColors.surfaceSecondary`

#### ViaplayCastingActiveView
- ✅ Barra de progreso: `VioColors.primary`
- ✅ Texto "LIVE": `VioColors.primary`
- ✅ Botón Play/Pause: `VioColors.primary` con `textOnPrimary`
- ✅ Botón Stop: `VioColors.error.opacity(0.8)`
- ✅ Chat input background: `VioColors.surfaceSecondary.opacity(0.5)`
- ✅ Chat background: `VioColors.surface.opacity(0.4)`
- ✅ Botones de chat: `VioColors.primary`

## Otros Valores Hardcodeados

### Tamaños de Fuente
- ✅ Usar tamaños estándar del sistema (14, 12, 10, etc.) - Mantener por ahora
- ⚠️ **Pendiente**: Evaluar si deben moverse a `VioTypography` del design system

### Spacing
- ✅ Reemplazados con `VioSpacing` (xs, sm, md, lg, xl)
- ✅ Padding horizontal: `VioSpacing.md` (16)
- ✅ Padding vertical: `VioSpacing.sm` (8)

### Border Radius
- ✅ Reemplazados con `VioBorderRadius`
- ✅ Cards: `VioBorderRadius.large` (20)
- ✅ Botones: `VioBorderRadius.medium` (12)
- ✅ Progress bars: `VioBorderRadius.small` (8)

### Shadows
- ✅ Mantener `Color.black.opacity(0.6)` para shadows (estándar de iOS)
- ⚠️ **Pendiente**: Evaluar si deben moverse a `VioShadow` del design system

### Imágenes Hardcodeadas
- ✅ `Image("logo1")` → Reemplazado con `CampaignSponsorBadge` del SDK
- ✅ `AsyncImage` → Reemplazado con `CachedAsyncImage` del SDK

### Textos Hardcodeados
- ⚠️ **Pendiente**: Evaluar si deben moverse a localización
  - "Sponset av"
  - "Resultater"
  - "Takk for at du stemte!"
  - "Bli med!"
  - "Du er med!"
  - "Legg til"
  - "Lagt til!"
  - "PREMIER"
  - "Frist:"
  - "Maks deltakere:"
  - "Trekking om Xs..."
  - "Casting to..."
  - "LIVE"
  - "LIVE CHAT"
  - "Send a message..."

## Archivos Migrados

### Componentes Migrados al SDK
- ✅ `ViaplayCastingPollCardView.swift` → `REngagementPollCard.swift`
- ✅ `ViaplayCastingContestCardView.swift` → `REngagementContestCard.swift`
- ✅ `ViaplayCastingProductCardView.swift` → `REngagementProductCard.swift`

### Componentes Base Creados
- ✅ `REngagementCardBase.swift` - Componente base compartido
- ✅ `REngagementDragIndicator.swift` - Indicador de drag
- ✅ `REngagementSponsorBadge.swift` - Badge de sponsor

### Componentes Compartidos Movidos al SDK
- ✅ `CachedAsyncImage.swift` → `ReachuDesignSystem/Components/`
- ✅ `CampaignSponsorBadge.swift` → `ReachuDesignSystem/Components/`

### Archivos Eliminados
- ✅ `ViaplayCastingPollCardView.swift` (demo)
- ✅ `ViaplayCastingContestCardView.swift` (demo)
- ✅ `ViaplayCastingProductCardView.swift` (demo)
- ✅ `EngagementManager.swift` (ReachuCore) → Movido a ReachuEngagementSystem
- ✅ `EngagementModels.swift` (ReachuCore) → Movido a ReachuEngagementSystem

## Valores Pendientes de Reemplazar

### En Otros Componentes del Demo (No Engagement)

Los siguientes componentes aún tienen valores hardcodeados pero NO son parte del engagement system:

1. **ViaplayPollOverlay.swift**
   - `ViaplayTheme.Colors.pink` (múltiples instancias)
   - `Color.white`, `Color.black.opacity(0.4)`
   - `Color(hex: "3A3D5C")`

2. **ViaplayContestOverlay.swift**
   - `ViaplayTheme.Colors.pink` (múltiples instancias)
   - `Color.green`
   - `Color(hex: "120019")`

3. **ViaplayOfferBannerView.swift**
   - `ViaplayTheme.Colors.pink`
   - `Color(hex: "1B1B25")`
   - `Color.white`

4. **Otros componentes del demo**
   - Varios componentes aún usan `ViaplayTheme.Colors.pink`
   - Estos NO son parte del engagement system de casting

## Notas

- Todos los componentes del engagement system de casting ahora usan `VioColors.adaptive(for:)` para soportar dark/light mode automático
- Los componentes usan `@Environment(\.colorScheme)` para adaptarse automáticamente
- Los componentes están completamente migrados al SDK y no dependen de valores hardcodeados del demo
- La migración mantiene la misma API pública para facilitar la integración

## Próximos Pasos Recomendados

1. ⚠️ Migrar otros overlays del demo (ViaplayPollOverlay, ViaplayContestOverlay) al SDK
2. ⚠️ Evaluar mover textos hardcodeados a sistema de localización
3. ⚠️ Evaluar crear tokens de tipografía en VioTypography
4. ⚠️ Evaluar crear tokens de shadows en VioShadow
5. ✅ Testing en light y dark mode
6. ✅ Documentación SwiftDoc para componentes públicos
