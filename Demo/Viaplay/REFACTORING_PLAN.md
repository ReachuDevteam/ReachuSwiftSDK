# Plan de Refactorización - LiveMatchView

## 🔍 Análisis de Duplicación de Código

### ❌ Problemas Identificados

#### 1. **ChatMessage y ChatManager Duplicados**
**Ubicación actual**: `ViaplayChatOverlay.swift` (líneas 368-479)
**También usado en**: `LiveMatchView.swift`

**Problema**: 
- Modelo `ChatMessage` definido dentro del overlay
- `ChatManager` con lógica de simulación embebida
- No reutilizable fuera del overlay

**Solución**: Mover a archivo separado `ChatModels.swift` y `ChatManager.swift`

#### 2. **VideoPlayerViewModel Duplicado**
**Ubicación**: `ViaplayVideoPlayer.swift`
**También usado en**: `LiveMatchView.swift`

**Problema**:
- Lógica de player repetida
- No compartida entre vistas

**Solución**: Crear `SharedVideoPlayerViewModel.swift`

#### 3. **Componentes UI No Reutilizables**
**En LiveMatchView.swift**:
- `chatMessageRow()` - función privada
- `pollCard()` - función privada  
- `timelineEventCard()` - función privada
- `highlightCard()` - función privada
- `statPreviewRow()` - función privada

**Problema**: Funciones privadas dentro de la vista (>1400 líneas)

**Solución**: Extraer a componentes independientes

#### 4. **Lógica de Negocio en Vistas**
- `mixedContentItems` - lógica compleja en computed property
- Filtrado de mensajes por minuto en la vista
- Cálculos de posiciones y timestamps

**Problema**: Vista con demasiada responsabilidad

**Solución**: Mover lógica a ViewModels/Managers

## 📁 Estructura Propuesta (Optimizada)

```
Demo/Viaplay/Viaplay/
├── Models/
│   ├── Match/
│   │   ├── MatchModels.swift                    ✅ Ya existe
│   │   ├── MatchStatisticsModels.swift          ✅ Ya existe
│   │   └── MatchTimelineModels.swift            🆕 Separar timeline
│   ├── Chat/
│   │   └── ChatModels.swift                     🆕 Extraer de overlay
│   └── Entertainment/
│       └── (ya existe en Components/Entertainment/)
│
├── Managers/
│   ├── Match/
│   │   ├── MatchSimulationManager.swift         ✅ Ya existe
│   │   └── LiveMatchViewModel.swift             🆕 Lógica de LiveMatchView
│   ├── Chat/
│   │   └── ChatManager.swift                    🆕 Extraer de overlay
│   └── Entertainment/
│       └── EntertainmentManager.swift           ✅ Ya existe
│
├── Components/
│   ├── Match/
│   │   ├── MatchHeaderView.swift                🆕 Header reutilizable
│   │   ├── MatchScoreView.swift                 🆕 Score display
│   │   └── VideoTimelineControl.swift           🆕 Timeline scrubber
│   ├── Chat/
│   │   ├── ChatMessageRow.swift                 🆕 Mensaje individual
│   │   ├── ChatListView.swift                   🆕 Lista de mensajes
│   │   └── ViaplayChatOverlay.swift             ✅ Simplificar
│   ├── Timeline/
│   │   ├── TimelineEventCard.swift              🆕 Evento del partido
│   │   └── HighlightCard.swift                  🆕 Highlight item
│   ├── Statistics/
│   │   ├── StatRow.swift                        🆕 Fila de estadística
│   │   └── StatPreviewCard.swift                🆕 Preview de stats
│   └── Polls/
│       └── PollCard.swift                       🆕 Card de poll
│
└── Views/
    └── LiveMatchView.swift                      🔄 Simplificar (solo composición)
```

## 🎯 Plan de Refactorización

### Fase 1: Extraer Modelos y Managers

#### 1.1 Crear `ChatModels.swift`
```swift
// Models/Chat/ChatModels.swift
import Foundation
import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let username: String
    let text: String
    let usernameColor: Color
    let likes: Int
    let timestamp: Date
}
```

#### 1.2 Crear `ChatManager.swift`
```swift
// Managers/Chat/ChatManager.swift
import Foundation
import Combine

@MainActor
class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var viewerCount: Int = 0
    
    // ... resto de la lógica
}
```

#### 1.3 Crear `LiveMatchViewModel.swift`
```swift
// Managers/Match/LiveMatchViewModel.swift
import Foundation
import Combine

@MainActor
class LiveMatchViewModel: ObservableObject {
    @Published var selectedTab: MatchTab = .all
    @Published var selectedMinute: Int? = nil
    
    let chatManager: ChatManager
    let matchSimulation: MatchSimulationManager
    let entertainmentManager: EntertainmentManager
    
    // Computed properties con lógica de negocio
    var mixedContentItems: [MixedContentItem] { ... }
    var currentFilterMinute: Int { ... }
    
    // Métodos de negocio
    func handlePollVote(componentId: String, optionId: String) async throws
    func jumpToMinute(_ minute: Int)
    func goToLive()
}
```

### Fase 2: Crear Componentes Reutilizables Pequeños

#### 2.1 `ChatMessageRow.swift` (componente atómico)
```swift
// Components/Chat/ChatMessageRow.swift
struct ChatMessageRow: View {
    let message: ChatMessage
    let compact: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Avatar
            ChatAvatar(
                initial: String(message.username.prefix(1)),
                color: message.usernameColor,
                size: compact ? 28 : 32
            )
            
            VStack(alignment: .leading, spacing: 2) {
                ChatMessageHeader(
                    username: message.username,
                    usernameColor: message.usernameColor,
                    timestamp: message.timestamp
                )
                
                Text(message.text)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.95))
            }
            Spacer()
        }
    }
}
```

#### 2.2 `ChatAvatar.swift` (componente atómico)
```swift
// Components/Chat/ChatAvatar.swift
struct ChatAvatar: View {
    let initial: String
    let color: Color
    let size: CGFloat = 32
    
    var body: some View {
        Circle()
            .fill(color.opacity(0.3))
            .frame(width: size, height: size)
            .overlay(
                Text(initial)
                    .font(.system(size: size * 0.4375, weight: .semibold))
                    .foregroundColor(color)
            )
    }
}
```

#### 2.3 `MatchScoreView.swift` (componente atómico)
```swift
// Components/Match/MatchScoreView.swift
struct MatchScoreView: View {
    let homeScore: Int
    let awayScore: Int
    let currentMinute: Int
    let isLive: Bool = true
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Text("\(homeScore)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                if isLive {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
                
                Text("\(awayScore)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text("\(currentMinute)'")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}
```

#### 2.4 `TeamLogoView.swift` (componente atómico)
```swift
// Components/Match/TeamLogoView.swift
struct TeamLogoView: View {
    let team: Team
    let size: CGFloat = 60
    let imageUrl: String?
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: imageUrl.flatMap(URL.init)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .overlay(
                        Text(team.shortName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: size, height: size)
            
            Text(team.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
}
```

#### 2.5 `TimelineEventCard.swift` (componente molecular)
```swift
// Components/Timeline/TimelineEventCard.swift
struct TimelineEventCard: View {
    let event: MatchEvent
    let showConnector: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            TimelineMinuteBadge(
                minute: event.minute,
                showConnector: showConnector
            )
            
            TimelineEventContent(event: event)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}
```

#### 2.6 `PollCard.swift` (componente molecular)
```swift
// Components/Polls/PollCard.swift
struct PollCard: View {
    let component: InteractiveComponent
    let hasResponded: Bool
    let onVote: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PollHeader(
                type: component.type,
                timeAgo: "9m"
            )
            
            Text(component.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            
            PollOptions(
                options: component.options,
                disabled: hasResponded,
                onSelect: onVote
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.2))
        )
    }
}
```

#### 2.7 `VideoTimelineControl.swift` (componente molecular)
```swift
// Components/Match/VideoTimelineControl.swift
struct VideoTimelineControl: View {
    @Binding var currentMinute: Int
    @Binding var selectedMinute: Int?
    let events: [MatchEvent]
    let totalDuration: Int = 90
    
    var body: some View {
        VStack(spacing: 8) {
            TimelineScrubber(
                currentMinute: currentMinute,
                selectedMinute: $selectedMinute,
                events: events,
                totalDuration: totalDuration
            )
            
            TimelineLabels(
                selectedMinute: selectedMinute,
                onGoLive: { selectedMinute = nil }
            )
        }
    }
}
```

### Fase 3: Simplificar LiveMatchView

**Antes** (1408 líneas):
```swift
struct LiveMatchView: View {
    // 20+ @State variables
    // 15+ computed properties
    // 25+ private functions
    
    var body: some View {
        // Vista monolítica
    }
    
    // 1300+ líneas de helpers privados
}
```

**Después** (~200 líneas):
```swift
struct LiveMatchView: View {
    @StateObject private var viewModel: LiveMatchViewModel
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                MatchHeaderView(
                    match: match,
                    homeScore: viewModel.matchSimulation.homeScore,
                    awayScore: viewModel.matchSimulation.awayScore,
                    currentMinute: viewModel.matchSimulation.currentMinute,
                    onDismiss: onDismiss
                )
                
                SponsorBanner()
                
                MatchNavigationTabs(
                    selectedTab: $viewModel.selectedTab
                )
                
                MatchContentView(
                    selectedTab: viewModel.selectedTab,
                    viewModel: viewModel
                )
                
                VideoTimelineControl(
                    currentMinute: viewModel.matchSimulation.currentMinute,
                    selectedMinute: $viewModel.selectedMinute,
                    events: viewModel.matchSimulation.events
                )
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}
```

## 📋 Checklist de Componentes a Crear

### Nivel Atómico (Componentes Básicos)

- [ ] `ChatAvatar.swift` - Avatar circular con inicial
- [ ] `ChatMessageHeader.swift` - Username + timestamp
- [ ] `TeamLogoView.swift` - Logo del equipo
- [ ] `MatchScoreView.swift` - Marcador del partido
- [ ] `LiveBadge.swift` - Badge de "LIVE"
- [ ] `TimelineScrubber.swift` - Barra de timeline
- [ ] `TimelineMinuteBadge.swift` - Badge de minuto
- [ ] `StatBar.swift` - Barra de estadística
- [ ] `ReactionButton.swift` - Botón de reacción emoji

### Nivel Molecular (Componentes Compuestos)

- [ ] `ChatMessageRow.swift` - Mensaje completo del chat
- [ ] `MatchHeaderView.swift` - Header con equipos y score
- [ ] `TimelineEventCard.swift` - Card de evento
- [ ] `HighlightCard.swift` - Card de highlight
- [ ] `PollCard.swift` - Card de poll
- [ ] `StatPreviewCard.swift` - Preview de estadísticas
- [ ] `LiveScoreItem.swift` - Item de live scores
- [ ] `SponsorBanner.swift` - Banner de sponsor
- [ ] `VideoTimelineControl.swift` - Control completo de timeline

### Nivel Organismo (Secciones)

- [ ] `ChatListView.swift` - Lista completa de chat
- [ ] `MatchNavigationTabs.swift` - Tabs de navegación
- [ ] `MatchContentView.swift` - Router de contenido por tab
- [ ] `AllContentFeed.swift` - Feed mezclado
- [ ] `HighlightsListView.swift` - Lista de highlights
- [ ] `LiveScoresListView.swift` - Lista de scores
- [ ] `PollsListView.swift` - Lista de polls

### Managers y ViewModels

- [ ] `ChatManager.swift` - Gestión de chat (extraer)
- [ ] `LiveMatchViewModel.swift` - ViewModel principal
- [ ] `SharedVideoPlayerViewModel.swift` - Player compartido

## 🚀 Implementación por Fases

### Fase 1: Extraer Modelos y Managers (1-2 horas)
1. Crear `Models/Chat/ChatModels.swift`
2. Crear `Managers/Chat/ChatManager.swift`
3. Crear `Managers/Match/LiveMatchViewModel.swift`
4. Actualizar imports en archivos existentes

### Fase 2: Crear Componentes Atómicos (2-3 horas)
1. `ChatAvatar.swift`
2. `TeamLogoView.swift`
3. `MatchScoreView.swift`
4. `LiveBadge.swift`
5. `TimelineMinuteBadge.swift`
6. `StatBar.swift`
7. `ReactionButton.swift`

### Fase 3: Crear Componentes Moleculares (3-4 horas)
1. `ChatMessageRow.swift`
2. `MatchHeaderView.swift`
3. `TimelineEventCard.swift`
4. `HighlightCard.swift`
5. `PollCard.swift`
6. `StatPreviewCard.swift`
7. `VideoTimelineControl.swift`

### Fase 4: Crear Componentes Organismo (2-3 horas)
1. `ChatListView.swift`
2. `MatchNavigationTabs.swift`
3. `MatchContentView.swift`
4. `AllContentFeed.swift`

### Fase 5: Refactorizar LiveMatchView (1-2 horas)
1. Reemplazar funciones privadas con componentes
2. Mover lógica al ViewModel
3. Simplificar a composición de componentes
4. Reducir de 1408 líneas a ~200 líneas

### Fase 6: Testing y Optimización (2-3 horas)
1. Probar cada componente individualmente
2. Verificar que LiveMatchView funciona igual
3. Optimizar performance
4. Agregar previews a cada componente

**Tiempo total estimado**: 11-17 horas

## 📐 Principios de Diseño

### 1. **Componentes Pequeños y Enfocados**
- Máximo 100 líneas por componente
- Una sola responsabilidad
- Props claras y tipadas

### 2. **Reutilización**
- Componentes usables en múltiples vistas
- Props configurables
- Temas y estilos consistentes

### 3. **Composición sobre Herencia**
- Componentes compuestos de componentes simples
- No duplicar código
- Fácil de mantener y testear

### 4. **Separación de Responsabilidades**
- Vistas: Solo UI
- ViewModels: Lógica de presentación
- Managers: Lógica de negocio
- Models: Datos

## 🎯 Beneficios

### Mantenibilidad
- ✅ Fácil encontrar y modificar código
- ✅ Componentes independientes y testeables
- ✅ Cambios aislados sin efectos secundarios

### Reutilización
- ✅ Componentes usables en otras vistas
- ✅ Fácil crear variaciones
- ✅ Menos código duplicado

### Performance
- ✅ SwiftUI optimiza mejor componentes pequeños
- ✅ Menos re-renders innecesarios
- ✅ Previews más rápidos

### Testabilidad
- ✅ Unit tests para cada componente
- ✅ Snapshot tests fáciles
- ✅ Lógica separada de UI

## 🔧 Ejemplo de Refactorización

### Antes (función privada en LiveMatchView):
```swift
private func chatMessageRow(_ message: ChatMessage) -> some View {
    HStack(alignment: .top, spacing: 8) {
        Circle()
            .fill(message.usernameColor.opacity(0.3))
            .frame(width: 32, height: 32)
            .overlay(
                Text(String(message.username.prefix(1)))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(message.usernameColor)
            )
        // ... 30 líneas más
    }
}
```

### Después (componente reutilizable):
```swift
// En LiveMatchView.swift
ChatMessageRow(message: message)

// En ChatMessageRow.swift (componente independiente)
struct ChatMessageRow: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ChatAvatar(
                initial: String(message.username.prefix(1)),
                color: message.usernameColor
            )
            ChatMessageContent(message: message)
            Spacer()
        }
    }
}
```

## 📊 Métricas de Mejora

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| Líneas en LiveMatchView | 1408 | ~200 | -86% |
| Componentes reutilizables | 0 | 20+ | ∞ |
| Archivos | 1 grande | 25+ pequeños | +modular |
| Testabilidad | Difícil | Fácil | +100% |
| Mantenibilidad | Baja | Alta | +200% |

## 🎯 Próximos Pasos

1. **Revisar este plan** contigo
2. **Priorizar fases** según necesidad
3. **Implementar fase por fase**
4. **Testing continuo** después de cada fase
5. **Documentar** componentes con previews

¿Quieres que empiece con alguna fase específica o prefieres que implemente todo el plan completo?


