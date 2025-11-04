# Campaign Lifecycle Integration - Reachu SDK

## Descripción

El SDK ahora incluye un sistema completo de gestión de campañas que permite controlar cuándo y cómo se muestran los componentes basándose en el ciclo de vida de la campaña.

## Comportamiento por Defecto

**Si no hay campaña configurada (`campaignId: 0`):**
- ✅ Todos los componentes funcionan normalmente
- ✅ No hay restricciones de visibilidad
- ✅ El SDK funciona como antes

**Si hay campaña configurada (`campaignId > 0`):**
- ✅ El SDK respeta el ciclo de vida de la campaña
- ✅ Los componentes se muestran solo cuando la campaña está activa
- ✅ Se reciben actualizaciones en tiempo real vía WebSocket

## Configuración

### Opción 1: Sin Campaña (Comportamiento Normal)

```json
{
  "apiKey": "your-api-key",
  "environment": "sandbox",
  "liveShow": {
    "campaignId": 0
  }
}
```

O simplemente omite `campaignId`:

```json
{
  "apiKey": "your-api-key",
  "environment": "sandbox"
}
```

### Opción 2: Con Campaña Activa

```json
{
  "apiKey": "your-api-key",
  "environment": "sandbox",
  "liveShow": {
    "campaignId": 10
  }
}
```

## Estados de Campaña

### 1. **Upcoming** (Antes de `startDate`)
- ❌ Componentes NO se muestran
- ❌ Componentes NO pueden activarse, incluso manualmente
- ⏳ Espera por evento `campaign_started`
- 🔌 WebSocket conectado pero esperando

### 2. **Active** (Entre `startDate` y `endDate`)
- ✅ Componentes se muestran normalmente
- ✅ Pueden activarse/desactivarse manualmente o por scheduling
- ✅ Recibe eventos en tiempo real
- ✅ Puede hacer fetch de componentes activos

### 3. **Ended** (Después de `endDate`)
- ❌ Todos los componentes se ocultan automáticamente
- 📨 Se recibe evento `campaign_ended` inmediatamente al conectar
- 🔌 WebSocket puede desconectarse

## Casos Especiales de Fechas

El SDK maneja correctamente estos casos especiales:

### Sin fechas configuradas
- ✅ Campaña siempre activa (comportamiento legacy)
- ✅ SDK funciona normalmente sin restricciones

### Solo `startDate` configurado
- ⏳ Upcoming antes de `startDate`
- ✅ Active después de `startDate` (nunca termina)

### Solo `endDate` configurado
- ✅ Active hasta `endDate`
- ❌ Ended después de `endDate`

### Ambos `startDate` y `endDate`
- ⏳ Upcoming antes de `startDate`
- ✅ Active entre `startDate` y `endDate`
- ❌ Ended después de `endDate`

## Comportamiento al Conectar WebSocket

Cuando tu app se conecta al WebSocket (`wss://your-domain/ws/{campaignId}`), el comportamiento depende del estado actual de la campaña:

| Estado de Campaña | Comportamiento al Conectar |
|-------------------|----------------------------|
| **Ended** | Backend envía `campaign_ended` **inmediatamente** |
| **Upcoming** | No se envía evento, espera por `campaign_started` |
| **Active** | No se envía evento, puede hacer fetch de componentes |

El SDK:
1. Hace `GET /api/campaigns/{campaignId}` para obtener el estado inicial
2. Determina el estado basándose en `startDate` y `endDate`
3. Conecta al WebSocket
4. Si está Active, hace fetch de componentes activos
5. Si está Ended, espera el evento `campaign_ended` del backend
6. Si está Upcoming, espera el evento `campaign_started`

## Reglas de Negocio Críticas

### 1. Componentes NO pueden activarse en estado Upcoming
- ❌ Incluso si el backend envía un evento de activación
- ❌ El SDK ignora eventos de activación si `campaignState == .upcoming`
- ✅ Solo se activan cuando la campaña está Active

### 2. Un componente por tipo garantizado
- ✅ Solo UN componente de cada tipo puede estar activo a la vez
- ✅ El SDK garantiza esto removiendo componentes del mismo tipo antes de agregar uno nuevo
- ✅ Puedes usar `activeComponents.first { $0.type == "banner" }` con confianza

### 3. Componentes se ocultan inmediatamente cuando campaña termina
- ❌ Todos los componentes se ocultan cuando se recibe `campaign_ended`
- ❌ No se procesan eventos de activación si `campaignState == .ended`

### 4. Soporte de Deeplinks
- ✅ Componentes Banner y OfferBanner soportan `deeplinkUrl` y `deeplinkAction`
- ✅ Si existe deeplink, tiene prioridad sobre `ctaLink`
- ✅ Permite navegación in-app (ej: `myapp://offers/weekly`)

## Eventos WebSocket

El SDK escucha automáticamente los siguientes eventos:

### `campaign_started`
```json
{
  "type": "campaign_started",
  "campaignId": 10,
  "startDate": "2024-12-25T10:00:00Z",
  "endDate": "2024-12-31T23:59:59Z"
}
```

**Acción:** La campaña se activa y se cargan los componentes activos.

### `campaign_ended`
```json
{
  "type": "campaign_ended",
  "campaignId": 10,
  "endDate": "2024-12-31T23:59:59Z"
}
```

**Acción:** Todos los componentes se ocultan inmediatamente.

### `component_status_changed`
```json
{
  "type": "component_status_changed",
  "campaignId": 10,
  "componentId": "banner-abc123",
  "status": "active",
  "component": {
    "id": "banner-abc123",
    "type": "banner",
    "name": "Welcome Banner",
    "config": {...}
  }
}
```

**Acción:** 
- Si `status === "active"`: Se muestra el componente
- Si `status === "inactive"`: Se oculta el componente

### `component_config_updated`
```json
{
  "type": "component_config_updated",
  "campaignId": 10,
  "componentId": "banner-abc123",
  "component": {
    "id": "banner-abc123",
    "type": "banner",
    "name": "Updated Banner",
    "config": {...}
  }
}
```

**Acción:** Se actualiza la configuración del componente existente.

## Uso en Código

### Verificar Estado de Campaña

```swift
import ReachuCore

// Verificar si la campaña está activa
if CampaignManager.shared.isCampaignActive {
    // Mostrar componentes
}

// Verificar estado específico
switch CampaignManager.shared.campaignState {
case .upcoming:
    print("Campaign hasn't started yet")
case .active:
    print("Campaign is active")
case .ended:
    print("Campaign has ended")
}
```

### Obtener Componentes Activos

```swift
// Verificar si un tipo de componente debe mostrarse
if CampaignManager.shared.shouldShowComponent(type: "banner") {
    // Mostrar banner
}

// Obtener componente activo por tipo
if let banner = CampaignManager.shared.getActiveComponent(type: "banner") {
    // Usar configuración del banner
    print("Banner title: \(banner.config)")
}
```

### Escuchar Eventos

```swift
import Combine

// Escuchar cuando la campaña termina
NotificationCenter.default.publisher(for: .campaignEnded)
    .sink { notification in
        let campaignId = notification.userInfo?["campaignId"] as? Int
        print("Campaign \(campaignId ?? 0) ended")
    }
    .store(in: &cancellables)
```

## Componentes que Respetan la Campaña

Todos estos componentes se ocultan automáticamente si la campaña no está activa:

- ✅ `RProductSlider` - Se oculta si la campaña no está activa
- ✅ `RCheckoutOverlay` - Se oculta si la campaña no está activa
- ✅ `RFloatingCartIndicator` - Se oculta si la campaña no está activa
- ✅ `RProductDetailOverlay` - Se oculta si la campaña no está activa
- ✅ Cualquier componente que use `ReachuComponentWrapper` o `.reachuOnly()`

### Uso del Helper Wrapper

Para componentes personalizados, puedes usar el wrapper:

```swift
// Opción 1: Usar ReachuComponentWrapper
ReachuComponentWrapper {
    YourCustomComponent()
}

// Opción 2: Usar el modificador .reachuOnly()
YourCustomComponent()
    .reachuOnly()
```

## Ejemplo Completo

```swift
import SwiftUI
import ReachuCore
import ReachuUI

@main
struct MyApp: App {
    init() {
        // Cargar configuración
        ConfigurationLoader.loadConfiguration()
        
        // El CampaignManager se inicializa automáticamente
        // Si campaignId > 0, se conecta al WebSocket
        // Si campaignId == 0, funciona normalmente sin restricciones
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var cartManager = CartManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    // Tu contenido normal
                    Text("My App Content")
                    
                    // Componentes de Reachu - se ocultan automáticamente si:
                    // 1. El mercado no está disponible
                    // 2. La campaña no está activa
                    RProductSlider(
                        title: "Recommended Products",
                        layout: .cards,
                        currency: cartManager.currency,
                        country: cartManager.country
                    )
                    .environmentObject(cartManager)
                }
            }
        }
        .environmentObject(cartManager)
        .overlay {
            // Cart indicator también respeta el estado de la campaña
            RFloatingCartIndicator()
                .environmentObject(cartManager)
        }
        .sheet(isPresented: $cartManager.isCheckoutPresented) {
            RCheckoutOverlay()
                .environmentObject(cartManager)
        }
    }
}
```

## API Endpoints

El SDK espera estos endpoints:

### GET `/api/campaigns/{campaignId}`
Obtiene información de la campaña incluyendo `startDate` y `endDate`.

### GET `/api/campaigns/{campaignId}/components`
Obtiene todos los componentes activos de la campaña.

### WebSocket `wss://your-domain/ws/{campaignId}`
Conexión WebSocket para recibir eventos en tiempo real.

## Manejo de Errores

### Campaña No Encontrada (404)
- El SDK funciona normalmente sin restricciones
- No se muestran errores al usuario

### Error de Conexión WebSocket
- Intento automático de reconexión con exponential backoff
- Máximo 5 intentos
- Si falla, el SDK funciona normalmente basándose en el estado inicial

### Unknown Component
- Silently ignored
- Does not affect other components

## Logs

### No Campaign
```
📋 [CampaignManager] No campaign configured (campaignId: 0) - SDK works normally
```

### Active Campaign
```
📋 [CampaignManager] Initializing campaign: 10
✅ [CampaignManager] Campaign 10 is active
✅ [CampaignManager] Loaded 3 active components
🔌 [CampaignWebSocket] Connecting to: wss://your-domain/ws/10
```

### Campaign Ended
```
❌ [CampaignManager] Campaign 10 has ended - hiding all components
📨 [CampaignWebSocket] Received event: campaign_ended
```

## Important Notes

1. **If `campaignId` is 0 or not set:** the SDK works normally without restrictions
2. **WebSocket connection:** connects automatically if `campaignId > 0`
3. **Auto-reconnect:** if the connection drops, reconnection is attempted automatically
4. **One component per type:** only one component of each type can be active at a time
5. **No dates configured:** if `startDate` or `endDate` are missing, the campaign is considered always active
