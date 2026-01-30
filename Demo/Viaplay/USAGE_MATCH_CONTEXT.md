# Uso de Match Context y Auto-Discovery en el Demo

## ✅ Integración Completada

El demo ahora está integrado con las nuevas funcionalidades de Match Context y Auto-Discovery del backend.

## Cómo Funciona

### 1. Match Context Automático

Cuando se abre el video player (`ViaplayVideoPlayer`), automáticamente:

1. **Crea un MatchContext** desde el modelo `Match` usando `match.toMatchContext()`
2. **Genera un matchId único** basado en los equipos y competencia
3. **Llama a `setupMatchContext()`** que:
   - Si `autoDiscover: true`: Usa `discoverCampaigns()` para encontrar campañas activas para ese match
   - Si `autoDiscover: false`: Solo establece el match context para filtrar componentes existentes

### 2. Configuración

En `reachu-config.json`:

```json
{
  "campaigns": {
    "autoDiscover": false,  // true = auto-discovery, false = legacy mode
    "channelId": null       // Opcional: ID del canal para match context
  },
  "liveShow": {
    "campaignId": 28        // Solo usado si autoDiscover: false
  }
}
```

### 3. Modos de Operación

#### Modo Auto-Discovery (`autoDiscover: true`)

- ✅ Descubre automáticamente todas las campañas activas para el match
- ✅ Soporta múltiples campañas simultáneas
- ✅ No requiere `campaignId` en configuración
- ✅ Usa solo `apiKey` del SDK (no `campaignAdminApiKey`)

**Ejemplo de uso:**
```swift
// En ViaplayVideoPlayer, automáticamente:
let matchContext = match.toMatchContext()
await campaignManager.discoverCampaigns(matchId: matchContext.matchId)
await campaignManager.setMatchContext(matchContext)
```

#### Modo Legacy (`autoDiscover: false`)

- ✅ Usa `campaignId` de `liveShow.campaignId`
- ✅ Carga una sola campaña específica
- ✅ Establece match context para filtrar componentes

**Ejemplo de uso:**
```swift
// En ViaplayVideoPlayer, automáticamente:
let matchContext = match.toMatchContext()
await campaignManager.setMatchContext(matchContext)
```

## Generación de Match ID

El helper `match.toMatchContext()` genera un `matchId` único:

- **Barcelona vs PSG**: `"barcelona-psg-2025-01-23"` (hardcoded para coincidir con backend)
- **Otros matches**: `"{homeTeam}-{awayTeam}-{competition}"` (normalizado a slug)

Ejemplo:
- Match: "Manchester City - Real Madrid" en "UEFA Champions League"
- MatchId: `"manchester-city-real-madrid-uefa-champions-league"`

## Componentes Filtrados por Match Context

Una vez establecido el match context:

- ✅ Los componentes (`activeComponents`) se filtran automáticamente por `matchContext`
- ✅ Solo se muestran componentes que coinciden con el `matchId` actual
- ✅ Los componentes sin `matchContext` se muestran para todos los matches (comportamiento legacy)

## Próximos Pasos

### Para Habilitar Auto-Discovery

1. Cambiar `autoDiscover: true` en `reachu-config.json`
2. Asegurarse de que `apiKey` esté configurado correctamente
3. El backend debe tener campañas con `matchId` correspondiente

### Para Usar Match Context en Otros Lugares

```swift
import ReachuCore

// Crear match context desde Match
let matchContext = match.toMatchContext(channelId: 1)

// Establecer en CampaignManager
await CampaignManager.shared.setMatchContext(matchContext)

// O descubrir campañas para un match específico
await CampaignManager.shared.discoverCampaigns(matchId: matchContext.matchId)
```

## Verificación

Para verificar que funciona:

1. Abrir el video player con un match (ej: Barcelona vs PSG)
2. Revisar logs en consola:
   ```
   🎯 [ViaplayVideoPlayer] Setting up match context: barcelona-psg-2025-01-23
   🎯 [ViaplayVideoPlayer] Auto-discovery enabled, discovering campaigns...
   ```
3. Verificar que `CampaignManager.shared.activeCampaigns` contiene las campañas correctas
4. Verificar que `CampaignManager.shared.activeComponents` está filtrado por match context

## Notas

- El match context se establece automáticamente cuando se abre el video player
- Si cambias de match, el match context se actualiza automáticamente
- Los componentes se filtran en tiempo real según el match context actual
- Backward compatible: funciona con campañas sin match context (legacy)
