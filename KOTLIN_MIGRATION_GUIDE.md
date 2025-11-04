# Guía de Migración para Desarrolladores Kotlin

Esta guía documenta todos los cambios recientes en el SDK Reachu para que puedan ser implementados en la versión Kotlin (Android).

---

## 📋 Tabla de Contenidos

1. [Resumen de Cambios](#resumen-de-cambios)
2. [Configuración JSON](#configuración-json)
3. [Sistema de Gestión de Campañas](#sistema-de-gestión-de-campañas)
4. [Nuevos Componentes de Campaña](#nuevos-componentes-de-campaña)
5. [WebSocket para Eventos de Campaña](#websocket-para-eventos-de-campaña)
6. [Estados de Campaña](#estados-de-campaña)
7. [Localización y Traducciones](#localización-y-traducciones)
8. [Componentes que Respetan el Estado de Campaña](#componentes-que-respetan-el-estado-de-campaña)
9. [Ejemplos de Implementación Kotlin](#ejemplos-de-implementación-kotlin)
10. [Endpoints de API](#endpoints-de-api)

---

## 🎯 Resumen de Cambios

### Cambios Principales

1. **Sistema de Gestión de Campañas**
   - Nuevo `CampaignManager` singleton para gestionar el ciclo de vida de campañas
   - Soporte para estados: `upcoming`, `active`, `ended`
   - Soporte para pausar/reanudar campañas
   - Control automático de visibilidad de componentes basado en estado de campaña

2. **Nuevos Componentes Auto-Configurados**
   - `RProductCarousel` - Carrusel horizontal de productos con auto-scroll
   - `RProductBanner` - Banner destacado de un producto
   - `RProductStore` - Vista tipo tienda (grid/list) de productos

3. **Configuración Actualizada**
   - `campaignId` movido al nivel raíz del JSON (no dentro de `liveShow`)
   - Nueva sección `campaigns` con URLs configurables para WebSocket y REST API
   - Sistema de localización mejorado con archivos de traducción separados

4. **WebSocket para Eventos de Campaña**
   - Conexión WebSocket separada para eventos de campaña
   - Eventos: `campaign_started`, `campaign_ended`, `campaign_paused`, `campaign_resumed`
   - Eventos de componentes: `component_status_changed`

---

## 📝 Configuración JSON

### Estructura Actualizada

```json
{
  "apiKey": "your-api-key",
  "campaignId": 14,  // ⚠️ MOVIDO AL NIVEL RAÍZ (antes estaba en liveShow.campaignId)
  "environment": "sandbox",
  
  "theme": { /* ... */ },
  "cart": { /* ... */ },
  "network": { /* ... */ },
  "ui": { /* ... */ },
  "marketFallback": { /* ... */ },
  
  "localization": {
    "defaultLanguage": "en",
    "fallbackLanguage": "en",
    "translationsFile": "reachu-translations"  // Nombre del archivo JSON sin extensión
  },
  
  "campaigns": {  // ⚠️ NUEVA SECCIÓN
    "webSocketBaseURL": "https://dev-campaing.reachu.io",
    "restAPIBaseURL": "https://dev-campaing.reachu.io"
  }
}
```

### Cambios Importantes

- ✅ `campaignId` ahora está en el nivel raíz (directamente bajo `apiKey`)
- ✅ Nueva sección `campaigns` con URLs configurables
- ✅ `localization.translationsFile` apunta al archivo de traducciones (sin `.json`)

---

## 🎮 Sistema de Gestión de Campañas

### CampaignManager (Singleton)

El `CampaignManager` es un singleton que gestiona todo el ciclo de vida de las campañas.

#### Propiedades Principales

```kotlin
object CampaignManager {
    // Estado de la campaña
    var isCampaignActive: Boolean = true  // Por defecto true (sin restricciones)
    var campaignState: CampaignState = CampaignState.ACTIVE
    var currentCampaign: Campaign? = null
    var activeComponents: List<Component> = emptyList()
    
    // Estado de conexión WebSocket
    var isConnected: Boolean = false
}
```

#### Estados de Campaña

```kotlin
enum class CampaignState {
    UPCOMING,  // Antes de startDate
    ACTIVE,    // Entre startDate y endDate
    ENDED      // Después de endDate
}
```

#### Modelo de Campaña

```kotlin
data class Campaign(
    val id: Int,
    val startDate: String?,      // ISO 8601 timestamp
    val endDate: String?,        // ISO 8601 timestamp
    val isPaused: Boolean?       // Estado de pausa (independiente de fechas)
) {
    /**
     * Determina el estado actual basado en fechas
     * Casos especiales:
     * - Sin fechas: Siempre activa (comportamiento legacy)
     * - Solo startDate: Activa después de start, nunca termina
     * - Solo endDate: Activa hasta endDate
     * - Ambas fechas: Respeta inicio y fin
     */
    fun getCurrentState(): CampaignState {
        val now = Instant.now()
        val start = startDate?.toInstant()
        val end = endDate?.toInstant()
        
        // Sin fechas: siempre activa
        if (start == null && end == null) return CampaignState.ACTIVE
        
        // Solo endDate: activa hasta endDate
        if (start == null && end != null) {
            return if (now.isAfter(end)) CampaignState.ENDED else CampaignState.ACTIVE
        }
        
        // Solo startDate: activa después de start
        if (end == null && start != null) {
            return if (now.isBefore(start)) CampaignState.UPCOMING else CampaignState.ACTIVE
        }
        
        // Ambas fechas presentes
        if (start != null && end != null) {
            return when {
                now.isBefore(start) -> CampaignState.UPCOMING
                now.isAfter(end) -> CampaignState.ENDED
                else -> CampaignState.ACTIVE
            }
        }
        
        return CampaignState.ACTIVE
    }
}
```

#### Decodificación Flexible de `isPaused`

⚠️ **IMPORTANTE**: El backend puede enviar `isPaused` como `String` (`"true"`/`"false"`) o como `Boolean`. El SDK debe manejar ambos casos:

```kotlin
data class Campaign(
    val id: Int,
    val startDate: String?,
    val endDate: String?,
    val isPaused: Boolean?
) {
    companion object {
        // Decodificador personalizado para manejar String o Boolean
        fun fromJson(json: JsonObject): Campaign {
            val isPausedValue = when {
                json.has("isPaused") && json["isPaused"].isJsonPrimitive -> {
                    val primitive = json["isPaused"].asJsonPrimitive
                    when {
                        primitive.isBoolean -> primitive.asBoolean
                        primitive.isString -> primitive.asString.lowercase() == "true"
                        else -> null
                    }
                }
                else -> null
            }
            
            return Campaign(
                id = json["id"].asInt,
                startDate = json["startDate"]?.asString,
                endDate = json["endDate"]?.asString,
                isPaused = isPausedValue
            )
        }
    }
}
```

### Inicialización del CampaignManager

```kotlin
// En Application.onCreate() o punto de entrada del SDK
fun initializeCampaign(campaignId: Int?) {
    if (campaignId == null || campaignId == 0) {
        // Sin campaña configurada - SDK funciona normalmente
        CampaignManager.isCampaignActive = true
        CampaignManager.campaignState = CampaignState.ACTIVE
        return
    }
    
    // 1. Obtener información de la campaña
    fetchCampaignInfo(campaignId)
    
    // 2. Conectar WebSocket para actualizaciones en tiempo real
    connectWebSocket(campaignId)
    
    // 3. Obtener componentes activos (solo si campaña está activa)
    if (CampaignManager.campaignState == CampaignState.ACTIVE && 
        CampaignManager.isCampaignActive && 
        CampaignManager.currentCampaign?.isPaused != true) {
        fetchActiveComponents(campaignId)
    }
}
```

### Métodos Principales del CampaignManager

```kotlin
object CampaignManager {
    /**
     * Verifica si un componente debe mostrarse
     */
    fun shouldShowComponent(type: String): Boolean {
        // Si no hay campaña configurada, mostrar todo
        if (campaignId == null || campaignId == 0) return true
        
        // Campaña debe estar activa
        if (!isCampaignActive) return false
        
        // Verificar si el componente está en la lista de activos
        return activeComponents.any { it.type == type && it.isActive }
    }
    
    /**
     * Obtiene un componente activo por tipo
     */
    fun getActiveComponent(type: String): Component? {
        if (!isCampaignActive) return null
        return activeComponents.firstOrNull { it.type == type && it.isActive }
    }
    
    /**
     * Obtiene todos los componentes activos de un tipo específico
     */
    fun getActiveComponents(type: String): List<Component> {
        if (!isCampaignActive) return emptyList()
        return activeComponents.filter { it.type == type && it.isActive }
    }
}
```

---

## 🎨 Nuevos Componentes de Campaña

### 1. ProductCarousel (Carrusel de Productos)

**Tipo en backend**: `product_carousel`

**Configuración**:
```kotlin
data class ProductCarouselConfig(
    val productIds: List<String>,
    val autoPlay: Boolean = true,
    val interval: Int = 3000  // milisegundos
)
```

**Ejemplo JSON desde backend**:
```json
{
  "componentId": "carousel-xyz789",
  "type": "product_carousel",
  "name": "Product Carousel",
  "config": {
    "productIds": ["123", "456", "789"],
    "autoPlay": true,
    "interval": 3000
  },
  "status": "active"
}
```

**Características**:
- ✅ Auto-scroll horizontal de productos
- ✅ Indicadores de página
- ✅ Configurable intervalo de auto-scroll
- ✅ Se oculta automáticamente si campaña no está activa

**Uso**:
```kotlin
// En Compose
@Composable
fun ProductCarousel() {
    val campaignManager = CampaignManager.getInstance()
    val component = campaignManager.getActiveComponent("product_carousel")
    
    if (component?.isActive == true && component.config is ProductCarouselConfig) {
        val config = component.config as ProductCarouselConfig
        HorizontalProductCarousel(
            productIds = config.productIds,
            autoPlay = config.autoPlay,
            interval = config.interval
        )
    }
}
```

### 2. ProductBanner (Banner de Producto)

**Tipo en backend**: `product_banner`

**Configuración**:
```kotlin
data class ProductBannerConfig(
    val productId: String,
    val backgroundImageUrl: String,
    val title: String,
    val subtitle: String? = null,
    val ctaText: String,
    val ctaLink: String? = null,
    val deeplink: String? = null
)
```

**Ejemplo JSON desde backend**:
```json
{
  "componentId": "banner-abc123",
  "type": "product_banner",
  "name": "Featured Product Banner",
  "config": {
    "productId": "123",
    "backgroundImageUrl": "https://storage.url/banner.jpg",
    "title": "Producto Destacado",
    "subtitle": "Oferta especial de la semana",
    "ctaText": "Ver Producto",
    "ctaLink": "https://tienda.com/producto/123",
    "deeplink": "myapp://product/123"
  },
  "status": "active"
}
```

**Características**:
- ✅ Muestra un producto destacado como banner
- ✅ Imagen de fondo personalizable
- ✅ Soporte para deep links
- ✅ CTA (Call-to-Action) configurable

**Uso**:
```kotlin
@Composable
fun ProductBanner() {
    val campaignManager = CampaignManager.getInstance()
    val component = campaignManager.getActiveComponent("product_banner")
    
    if (component?.isActive == true && component.config is ProductBannerConfig) {
        val config = component.config as ProductBannerConfig
        ProductBannerView(
            productId = config.productId,
            backgroundImageUrl = config.backgroundImageUrl,
            title = config.title,
            subtitle = config.subtitle,
            ctaText = config.ctaText,
            onCtaClick = { 
                // Manejar ctaLink o deeplink
                handleCtaClick(config.ctaLink, config.deeplink)
            }
        )
    }
}
```

### 3. ProductStore (Tienda de Productos)

**Tipo en backend**: `product_store`

**Configuración**:
```kotlin
data class ProductStoreConfig(
    val mode: String,  // "all" o "filtered"
    val productIds: List<String>? = null,  // Solo si mode == "filtered"
    val displayType: String = "grid",  // "grid" o "list"
    val columns: Int = 2  // Solo para grid
)
```

**Ejemplo JSON desde backend**:
```json
{
  "componentId": "store-xyz789",
  "type": "product_store",
  "name": "Product Store",
  "config": {
    "mode": "filtered",
    "productIds": ["123", "456", "789"],
    "displayType": "grid",
    "columns": 2
  },
  "status": "active"
}
```

**Características**:
- ✅ Vista tipo tienda (grid o lista)
- ✅ Modo "all" (todos los productos) o "filtered" (lista específica)
- ✅ Configurable número de columnas (grid)
- ✅ Layout responsive

**Uso**:
```kotlin
@Composable
fun ProductStore() {
    val campaignManager = CampaignManager.getInstance()
    val component = campaignManager.getActiveComponent("product_store")
    
    if (component?.isActive == true && component.config is ProductStoreConfig) {
        val config = component.config as ProductStoreConfig
        
        when (config.displayType) {
            "grid" -> GridProductStore(
                mode = config.mode,
                productIds = config.productIds,
                columns = config.columns
            )
            "list" -> ListProductStore(
                mode = config.mode,
                productIds = config.productIds
            )
        }
    }
}
```

---

## 🔌 WebSocket para Eventos de Campaña

### Endpoint

```
wss://{campaignWebSocketBaseURL}/ws/{campaignId}
```

**Ejemplo**: `wss://dev-campaing.reachu.io/ws/14`

### Autenticación

Incluir header `X-API-Key` con el API key:

```kotlin
val request = Request.Builder()
    .url("wss://dev-campaing.reachu.io/ws/14")
    .addHeader("X-API-Key", apiKey)
    .build()
```

### Eventos Soportados

#### 1. campaign_started

```json
{
  "type": "campaign_started",
  "campaignId": 14,
  "startDate": "2025-11-04T10:24:00.000Z",
  "endDate": "2025-11-05T10:24:00.000Z"
}
```

**Acción**:
- Establecer `isCampaignActive = true`
- Establecer `campaignState = CampaignState.ACTIVE`
- Actualizar `currentCampaign` con nuevas fechas
- Obtener componentes activos: `fetchActiveComponents(campaignId)`

#### 2. campaign_ended

```json
{
  "type": "campaign_ended",
  "campaignId": 14,
  "endDate": "2025-11-05T10:24:00.000Z"
}
```

**Acción**:
- Establecer `isCampaignActive = false`
- Establecer `campaignState = CampaignState.ENDED`
- Limpiar `activeComponents` (ocultar todos los componentes)
- Actualizar `currentCampaign.endDate`

#### 3. campaign_paused

```json
{
  "type": "campaign_paused",
  "campaignId": 14
}
```

**Acción**:
- Establecer `isCampaignActive = false`
- Establecer `currentCampaign.isPaused = true`
- Limpiar `activeComponents` (ocultar todos los componentes)

#### 4. campaign_resumed

```json
{
  "type": "campaign_resumed",
  "campaignId": 14
}
```

**Acción**:
- Establecer `isCampaignActive = true`
- Establecer `currentCampaign.isPaused = false`
- Obtener componentes activos: `fetchActiveComponents(campaignId)`

#### 5. component_status_changed

```json
{
  "type": "component_status_changed",
  "campaignId": 14,
  "componentId": "carousel-xyz789",
  "status": "active",  // o "inactive"
  "component": {
    "id": "carousel-xyz789",
    "type": "product_carousel",
    "name": "Product Carousel",
    "config": {
      "productIds": ["123", "456", "789"],
      "autoPlay": true,
      "interval": 3000
    }
  }
}
```

**Acción**:
- Si `status == "active"`: Agregar/actualizar componente en `activeComponents`
- Si `status == "inactive"`: Remover componente de `activeComponents`

### Implementación Kotlin (OkHttp WebSocket)

```kotlin
class CampaignWebSocketManager(
    private val campaignId: Int,
    private val baseURL: String,
    private val apiKey: String
) {
    private var webSocket: WebSocket? = null
    private var reconnectAttempts = 0
    private val maxReconnectAttempts = 5
    
    fun connect() {
        val url = "$baseURL/ws/$campaignId"
        val request = Request.Builder()
            .url(url)
            .addHeader("X-API-Key", apiKey)
            .build()
        
        val client = OkHttpClient.Builder()
            .pingInterval(30, TimeUnit.SECONDS)  // Keep-alive automático
            .build()
        
        webSocket = client.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                reconnectAttempts = 0
                CampaignManager.isConnected = true
                Log.d("CampaignWebSocket", "Connected to: $url")
            }
            
            override fun onMessage(webSocket: WebSocket, text: String) {
                handleMessage(text)
            }
            
            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                CampaignManager.isConnected = false
                Log.e("CampaignWebSocket", "Error: ${t.message}")
                
                // Reintentar con backoff exponencial
                if (reconnectAttempts < maxReconnectAttempts) {
                    val delay = minOf(1000L * (1 shl reconnectAttempts), 30000L)
                    reconnectAttempts++
                    Handler(Looper.getMainLooper()).postDelayed({
                        connect()
                    }, delay)
                }
            }
            
            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                CampaignManager.isConnected = false
            }
        })
    }
    
    private fun handleMessage(text: String) {
        try {
            val json = JsonParser.parseString(text).asJsonObject
            val type = json["type"].asString
            
            when (type) {
                "campaign_started" -> handleCampaignStarted(json)
                "campaign_ended" -> handleCampaignEnded(json)
                "campaign_paused" -> handleCampaignPaused(json)
                "campaign_resumed" -> handleCampaignResumed(json)
                "component_status_changed" -> handleComponentStatusChanged(json)
            }
        } catch (e: Exception) {
            Log.e("CampaignWebSocket", "Error parsing message: ${e.message}")
        }
    }
    
    private fun handleCampaignStarted(json: JsonObject) {
        val campaignId = json["campaignId"].asInt
        val startDate = json["startDate"]?.asString
        val endDate = json["endDate"]?.asString
        
        CampaignManager.isCampaignActive = true
        CampaignManager.campaignState = CampaignState.ACTIVE
        
        // Actualizar campaña actual
        CampaignManager.currentCampaign = Campaign(
            id = campaignId,
            startDate = startDate,
            endDate = endDate,
            isPaused = false
        )
        
        // Obtener componentes activos
        fetchActiveComponents(campaignId)
    }
    
    private fun handleCampaignEnded(json: JsonObject) {
        val campaignId = json["campaignId"].asInt
        val endDate = json["endDate"]?.asString
        
        CampaignManager.isCampaignActive = false
        CampaignManager.campaignState = CampaignState.ENDED
        CampaignManager.activeComponents = emptyList()
        
        // Actualizar fecha de fin
        CampaignManager.currentCampaign?.let { campaign ->
            CampaignManager.currentCampaign = campaign.copy(endDate = endDate)
        }
    }
    
    private fun handleCampaignPaused(json: JsonObject) {
        val campaignId = json["campaignId"].asInt
        
        CampaignManager.isCampaignActive = false
        CampaignManager.activeComponents = emptyList()
        
        // Actualizar estado de pausa
        CampaignManager.currentCampaign?.let { campaign ->
            CampaignManager.currentCampaign = campaign.copy(isPaused = true)
        }
    }
    
    private fun handleCampaignResumed(json: JsonObject) {
        val campaignId = json["campaignId"].asInt
        
        CampaignManager.isCampaignActive = true
        
        // Actualizar estado de pausa
        CampaignManager.currentCampaign?.let { campaign ->
            CampaignManager.currentCampaign = campaign.copy(isPaused = false)
        }
        
        // Obtener componentes activos
        fetchActiveComponents(campaignId)
    }
    
    private fun handleComponentStatusChanged(json: JsonObject) {
        val status = json["status"].asString
        val componentData = json["component"]?.asJsonObject
        
        if (componentData != null) {
            val component = Component.fromJson(componentData)
            
            if (status == "active") {
                // Agregar o actualizar componente
                val currentComponents = CampaignManager.activeComponents.toMutableList()
                val index = currentComponents.indexOfFirst { it.id == component.id }
                if (index >= 0) {
                    currentComponents[index] = component
                } else {
                    currentComponents.add(component)
                }
                CampaignManager.activeComponents = currentComponents
            } else {
                // Remover componente
                CampaignManager.activeComponents = CampaignManager.activeComponents
                    .filter { it.id != component.id }
            }
        }
    }
    
    fun disconnect() {
        webSocket?.close(1000, "Normal closure")
        webSocket = null
    }
}
```

---

## 📊 Estados de Campaña

### Comportamiento por Estado

#### 1. **UPCOMING** (Antes de `startDate`)
- ❌ Componentes **NO se muestran**
- ⏳ Espera por evento `campaign_started`
- 🔌 WebSocket conectado pero esperando
- ⚠️ `isCampaignActive = false`

#### 2. **ACTIVE** (Entre `startDate` y `endDate`)
- ✅ Componentes se muestran normalmente
- ✅ Pueden activarse/desactivarse manualmente o por scheduling
- ✅ Recibe eventos en tiempo real
- ✅ Puede hacer fetch de componentes activos
- ✅ `isCampaignActive = true` (a menos que esté pausada)

#### 3. **ENDED** (Después de `endDate`)
- ❌ Todos los componentes **automáticamente ocultos**
- 📨 Se recibe evento `campaign_ended` inmediatamente al conectar
- 🔌 WebSocket puede desconectarse
- ⚠️ `isCampaignActive = false`

### Casos Especiales

#### Sin fechas configuradas
- ✅ Campaña siempre activa (comportamiento legacy)
- ✅ SDK funciona normalmente sin restricciones

#### Solo `startDate`
- ✅ Campaña activa después de `startDate`
- ✅ Nunca termina

#### Solo `endDate`
- ✅ Campaña activa hasta `endDate`
- ✅ Termina cuando se alcanza `endDate`

#### Campaña pausada (`isPaused: true`)
- ❌ Todos los componentes ocultos
- ⚠️ `isCampaignActive = false`
- ⏸️ Estado independiente de fechas
- ▶️ Se puede reanudar con `campaign_resumed`

---

## 🌍 Localización y Traducciones

### Estructura de Archivo de Traducciones

Archivo: `reachu-translations.json`

```json
{
  "de": {
    "cart": {
      "title": "Warenkorb",
      "empty": "Ihr Warenkorb ist leer",
      "checkout": "Zur Kasse",
      "continueShopping": "Weiter einkaufen"
    },
    "checkout": {
      "title": "Kasse",
      "shipping": "Versand",
      "total": "Gesamt",
      "placeOrder": "Bestellung aufgeben"
    },
    "product": {
      "addToCart": "In den Warenkorb",
      "outOfStock": "Nicht vorrätig",
      "price": "Preis"
    }
  },
  "es": {
    "cart": {
      "title": "Carrito",
      "empty": "Tu carrito está vacío",
      "checkout": "Pagar",
      "continueShopping": "Seguir comprando"
    }
  }
}
```

### Configuración

```json
{
  "localization": {
    "defaultLanguage": "en",
    "fallbackLanguage": "en",
    "translationsFile": "reachu-translations"
  }
}
```

### Implementación Kotlin

```kotlin
class ReachuLocalization {
    private var translations: Map<String, Map<String, Any>> = emptyMap()
    private var currentLanguage: String = "en"
    private var fallbackLanguage: String = "en"
    
    fun configure(
        translationsFile: String,
        defaultLanguage: String = "en",
        fallbackLanguage: String = "en"
    ) {
        this.currentLanguage = defaultLanguage
        this.fallbackLanguage = fallbackLanguage
        
        // Cargar traducciones desde assets
        loadTranslations(translationsFile)
    }
    
    private fun loadTranslations(fileName: String) {
        try {
            val inputStream = context.assets.open("$fileName.json")
            val json = JsonParser.parseString(inputStream.bufferedReader().use { it.readText() })
            translations = json.asJsonObject.entrySet().associate { entry ->
                entry.key to parseTranslationObject(entry.value.asJsonObject)
            }
        } catch (e: Exception) {
            Log.e("Localization", "Error loading translations: ${e.message}")
        }
    }
    
    fun getString(key: String, vararg args: Any): String {
        val keys = key.split(".")
        val value = getNestedValue(translations[currentLanguage], keys)
            ?: getNestedValue(translations[fallbackLanguage], keys)
            ?: key  // Fallback a la clave si no se encuentra
        
        return if (args.isNotEmpty()) {
            String.format(value, *args)
        } else {
            value
        }
    }
    
    private fun getNestedValue(map: Map<String, Any>?, keys: List<String>): String? {
        if (keys.isEmpty() || map == null) return null
        
        val firstKey = keys[0]
        val value = map[firstKey] ?: return null
        
        if (keys.size == 1) {
            return value as? String
        }
        
        return getNestedValue(value as? Map<String, Any>, keys.drop(1))
    }
}
```

### Uso en Componentes

```kotlin
val localization = ReachuLocalization.getInstance()
val cartTitle = localization.getString("cart.title")  // "Warenkorb" (si currentLanguage == "de")
val checkoutButton = localization.getString("checkout.placeOrder")  // "Bestellung aufgeben"
```

---

## 🎯 Componentes que Respetan el Estado de Campaña

Todos los componentes del SDK deben verificar el estado de la campaña antes de mostrarse.

### Lógica de Visibilidad

```kotlin
fun shouldShowComponent(): Boolean {
    val config = ReachuConfiguration.shared
    val campaignId = config.campaignId
    
    // Si no hay campaña configurada (campaignId == 0), mostrar todo (legacy behavior)
    if (campaignId == null || campaignId == 0) {
        return true
    }
    
    // Campaña debe estar activa
    if (!CampaignManager.isCampaignActive) {
        return false
    }
    
    // Campaña no debe estar pausada
    if (CampaignManager.currentCampaign?.isPaused == true) {
        return false
    }
    
    // Si hay componentes activos configurados, verificar si este tipo está activo
    if (CampaignManager.activeComponents.isNotEmpty()) {
        return CampaignManager.shouldShowComponent("product_slider")  // o el tipo correspondiente
    }
    
    // Si no hay componentes configurados, mostrar si campaña está activa
    return true
}
```

### Componentes Actualizados

Los siguientes componentes ahora respetan el estado de campaña:

1. ✅ `RProductSlider` (ProductSlider)
2. ✅ `RCheckoutOverlay` (CheckoutOverlay)
3. ✅ `RFloatingCartIndicator` (FloatingCartIndicator)
4. ✅ `RProductCarousel` (ProductCarousel) - Nuevo
5. ✅ `RProductBanner` (ProductBanner) - Nuevo
6. ✅ `RProductStore` (ProductStore) - Nuevo

---

## 💻 Ejemplos de Implementación Kotlin

### 1. Inicialización del SDK

```kotlin
class ReachuApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Cargar configuración desde JSON
        val config = ConfigurationLoader.loadConfiguration(
            fileName = "reachu-config",
            context = this
        )
        
        // Configurar SDK
        ReachuConfiguration.configure(
            apiKey = config.apiKey,
            environment = config.environment,
            campaignId = config.campaignId,  // Del nivel raíz
            campaignConfig = CampaignConfiguration(
                webSocketBaseURL = config.campaigns.webSocketBaseURL,
                restAPIBaseURL = config.campaigns.restAPIBaseURL
            ),
            localizationConfig = LocalizationConfiguration(
                defaultLanguage = config.localization.defaultLanguage,
                fallbackLanguage = config.localization.fallbackLanguage,
                translationsFile = config.localization.translationsFile
            )
        )
        
        // Inicializar campaña si está configurada
        if (config.campaignId != null && config.campaignId > 0) {
            CampaignManager.initializeCampaign(config.campaignId)
        }
    }
}
```

### 2. Uso de Componentes Auto-Configurados

```kotlin
@Composable
fun HomeScreen() {
    Column {
        // Product Carousel - se configura automáticamente desde la campaña
        ProductCarousel()
        
        // Product Banner - se configura automáticamente desde la campaña
        ProductBanner()
        
        // Product Store - se configura automáticamente desde la campaña
        ProductStore()
        
        // Product Slider (legacy) - respeta el estado de campaña
        ProductSlider(
            title = "Productos Recomendados",
            onProductTap = { product -> /* ... */ }
        )
    }
}
```

### 3. Observar Cambios de Estado de Campaña

```kotlin
@Composable
fun CampaignAwareScreen() {
    val campaignState by CampaignManager.campaignState.collectAsState()
    val isCampaignActive by CampaignManager.isCampaignActive.collectAsState()
    
    LaunchedEffect(campaignState, isCampaignActive) {
        when (campaignState) {
            CampaignState.UPCOMING -> {
                // Mostrar mensaje "Campaña próximamente"
            }
            CampaignState.ACTIVE -> {
                if (isCampaignActive) {
                    // Mostrar componentes normalmente
                } else {
                    // Campaña pausada
                }
            }
            CampaignState.ENDED -> {
                // Ocultar componentes
            }
        }
    }
    
    // UI del componente
}
```

### 4. Manejo de Eventos WebSocket

```kotlin
class CampaignWebSocketListener : WebSocketListener() {
    override fun onMessage(webSocket: WebSocket, text: String) {
        val event = parseCampaignEvent(text)
        
        when (event.type) {
            "campaign_started" -> {
                // Actualizar UI para mostrar componentes
                CampaignManager.handleCampaignStarted(event)
            }
            "campaign_ended" -> {
                // Ocultar todos los componentes
                CampaignManager.handleCampaignEnded(event)
            }
            "campaign_paused" -> {
                // Ocultar componentes temporalmente
                CampaignManager.handleCampaignPaused(event)
            }
            "campaign_resumed" -> {
                // Mostrar componentes nuevamente
                CampaignManager.handleCampaignResumed(event)
            }
            "component_status_changed" -> {
                // Actualizar componente específico
                CampaignManager.handleComponentStatusChanged(event)
            }
        }
    }
}
```

---

## 🔗 Endpoints de API

### 1. Obtener Información de Campaña

```
GET {restAPIBaseURL}/api/campaigns/{campaignId}
```

**Headers**:
```
X-API-Key: {apiKey}
Content-Type: application/json
Accept: application/json
```

**Response**:
```json
{
  "id": 14,
  "userId": 1,
  "name": "Pregnancy",
  "startDate": "2025-11-04T10:24:00.000Z",
  "endDate": "2025-11-05T10:24:00.000Z",
  "isPaused": false,  // Puede ser String "true"/"false" o Boolean
  "reachuChannelId": null,
  "reachuApiKey": null
}
```

### 2. Obtener Componentes Activos

```
GET {restAPIBaseURL}/api/campaigns/{campaignId}/components
```

**Headers**:
```
X-API-Key: {apiKey}
Content-Type: application/json
Accept: application/json
```

**Response**:
```json
[
  {
    "componentId": "carousel-xyz789",
    "type": "product_carousel",
    "name": "Product Carousel",
    "config": {
      "productIds": ["123", "456", "789"],
      "autoPlay": true,
      "interval": 3000
    },
    "status": "active",
    "activatedAt": "2024-12-01T11:00:00.000Z"
  },
  {
    "componentId": "banner-abc123",
    "type": "product_banner",
    "name": "Featured Product Banner",
    "config": {
      "productId": "123",
      "backgroundImageUrl": "https://storage.url/banner.jpg",
      "title": "Producto Destacado",
      "subtitle": "Oferta especial",
      "ctaText": "Ver Producto",
      "ctaLink": "https://tienda.com/producto/123"
    },
    "status": "active",
    "activatedAt": "2024-12-01T10:30:00.000Z"
  }
]
```

### 3. WebSocket Connection

```
wss://{webSocketBaseURL}/ws/{campaignId}
```

**Headers**:
```
X-API-Key: {apiKey}
```

---

## 📝 Resumen de Cambios para Implementar

### Checklist de Implementación

- [ ] **Configuración JSON**
  - [ ] Mover `campaignId` al nivel raíz
  - [ ] Agregar sección `campaigns` con URLs configurables
  - [ ] Actualizar `localization.translationsFile`

- [ ] **CampaignManager**
  - [ ] Crear singleton `CampaignManager`
  - [ ] Implementar estados `UPCOMING`, `ACTIVE`, `ENDED`
  - [ ] Implementar modelo `Campaign` con decodificación flexible de `isPaused`
  - [ ] Implementar métodos `shouldShowComponent()`, `getActiveComponent()`, etc.

- [ ] **WebSocket**
  - [ ] Implementar `CampaignWebSocketManager`
  - [ ] Manejar eventos: `campaign_started`, `campaign_ended`, `campaign_paused`, `campaign_resumed`, `component_status_changed`
  - [ ] Implementar reconexión con backoff exponencial
  - [ ] Agregar header `X-API-Key` para autenticación

- [ ] **Nuevos Componentes**
  - [ ] `ProductCarousel` con auto-scroll
  - [ ] `ProductBanner` con imagen de fondo
  - [ ] `ProductStore` con modo grid/list

- [ ] **Componentes Existentes**
  - [ ] Actualizar `ProductSlider` para respetar estado de campaña
  - [ ] Actualizar `CheckoutOverlay` para respetar estado de campaña
  - [ ] Actualizar `FloatingCartIndicator` para respetar estado de campaña

- [ ] **Localización**
  - [ ] Implementar `ReachuLocalization`
  - [ ] Cargar traducciones desde archivo JSON
  - [ ] Implementar fallback a idioma por defecto

- [ ] **Endpoints**
  - [ ] `GET /api/campaigns/{campaignId}` - Obtener info de campaña
  - [ ] `GET /api/campaigns/{campaignId}/components` - Obtener componentes activos
  - [ ] `wss://{baseURL}/ws/{campaignId}` - WebSocket para eventos

---

## 🚀 Próximos Pasos

1. **Revisar esta guía** con el equipo de desarrollo Kotlin
2. **Crear issues** en el repositorio de Android para cada tarea
3. **Implementar paso a paso** siguiendo el checklist
4. **Probar** con los mismos endpoints de desarrollo que usa el SDK Swift
5. **Documentar** cualquier diferencia o ajuste necesario para Android

---

## 📞 Soporte

Si tienes preguntas sobre la implementación, consulta:

- Código fuente del SDK Swift: `/Users/angelo/ReachuSwiftSDK/Sources/ReachuCore/`
- Documentación de campañas: `CAMPAIGN_LIFECYCLE.md`
- Ejemplos de configuración: `/Users/angelo/PregancyDemo/PregancyDemo/Configuration/`

---

**Última actualización**: Diciembre 2024

