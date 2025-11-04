# 🌍 Guía para Desarrolladores Kotlin - Sistema de Traducciones Reachu SDK

## Descripción

Este documento explica cómo mantener y actualizar las traducciones del Reachu SDK para iOS/Swift desde el backend Kotlin.

## Estructura del Archivo de Traducciones

El SDK carga las traducciones desde un archivo JSON con la siguiente estructura:

**Formato Directo (Recomendado):**
```json
{
  "de": {
    "cart.title": "Warenkorb",
    "cart.empty": "Ihr Warenkorb ist leer",
    "checkout.title": "Zur Kasse",
    "common.addToCart": "In den Warenkorb",
    "common.close": "Schließen"
  },
  "es": {
    "cart.title": "Carrito",
    "cart.empty": "Tu carrito está vacío",
    "checkout.title": "Checkout",
    "common.addToCart": "Añadir al carrito",
    "common.close": "Cerrar"
  }
}
```

**Formato con Wrapper (También soportado):**
```json
{
  "translations": {
    "de": {
      "cart.title": "Warenkorb",
      "cart.empty": "Ihr Warenkorb ist leer"
    },
    "es": {
      "cart.title": "Carrito",
      "cart.empty": "Tu carrito está vacío"
    }
  }
}
```

**⚠️ IMPORTANTE:** 
- El SDK soporta ambos formatos, pero el formato directo es más simple y eficiente
- **NO incluyas traducciones en inglés** - El SDK tiene traducciones en inglés por defecto (`ReachuTranslationKey.defaultEnglish`)
- Solo incluye los idiomas que necesitas traducir (ej: alemán, español, noruego, etc.)

## Ubicación del Archivo

El archivo debe estar en el bundle de la app iOS con el nombre:
- `reachu-translations.json` (por defecto)
- O el nombre especificado en `reachu-config.json` → `localization.translationsFile`

### Configuración en reachu-config.json

```json
{
  "apiKey": "your-api-key",
  "environment": "sandbox",
  "localization": {
    "defaultLanguage": "en",
    "fallbackLanguage": "en",
    "translationsFile": "reachu-translations"
  }
}
```

## Sistema de Detección Automática de Idioma

El SDK detecta automáticamente el idioma basado en el país del usuario:

### Mapeo País → Idioma

Cuando se inicializa el SDK con `ConfigurationLoader.loadConfiguration(userCountryCode: "DE")`, el SDK automáticamente:

1. **Mapea el país al idioma:**
   - `DE` → `de` (Alemán)
   - `ES` → `es` (Español)
   - `NO` → `no` (Noruego)
   - `US` → `en` (Inglés)
   - etc.

2. **Verifica si hay traducciones disponibles** para ese idioma

3. **Establece el idioma automáticamente** si hay traducciones, de lo contrario usa el idioma por defecto

### Ejemplo de Flujo

```swift
// En la app iOS
ConfigurationLoader.loadConfiguration(userCountryCode: "DE")
// → SDK detecta: DE → de
// → Busca traducciones para "de" en reachu-translations.json
// → Si encuentra: Establece idioma = "de"
// → Si no encuentra: Usa "en" (default)
```

**Para desarrolladores Kotlin:** Asegúrate de que tus traducciones estén disponibles para los países que soportas. El SDK automáticamente seleccionará el idioma correcto.

## Keys de Traducción Disponibles

### 📋 Common (Común)
- `common.addToCart` - "Add to Cart"
- `common.remove` - "Remove"
- `common.close` - "Close"
- `common.cancel` - "Cancel"
- `common.confirm` - "Confirm"
- `common.continue` - "Continue"
- `common.back` - "Back"
- `common.next` - "Next"
- `common.done` - "Done"
- `common.loading` - "Loading..."
- `common.error` - "Error"
- `common.success` - "Success"
- `common.retry` - "Retry"
- `common.apply` - "Apply"
- `common.save` - "Save"
- `common.edit` - "Edit"
- `common.delete` - "Delete"

### 🛒 Cart (Carrito)
- `cart.title` - "Cart"
- `cart.empty` - "Your cart is empty"
- `cart.emptyMessage` - "Add products to continue with checkout"
- `cart.itemCount` - "Items"
- `cart.items` - "items"
- `cart.item` - "item"
- `cart.quantity` - "Quantity"
- `cart.subtotal` - "Subtotal"
- `cart.total` - "Total"
- `cart.shipping` - "Shipping"
- `cart.tax` - "Tax"
- `cart.discount` - "Discount"
- `cart.removeItem` - "Remove item"
- `cart.updateQuantity` - "Update quantity"

### 💳 Checkout
- `checkout.title` - "Checkout"
- `checkout.proceed` - "Proceed to Checkout"
- `checkout.initiatePayment` - "Initiate Payment"
- `checkout.completePurchase` - "Complete Purchase"
- `checkout.purchaseComplete` - "Purchase Complete!"
- `checkout.purchaseCompleteMessage` - "Your order has been confirmed. You'll receive an email confirmation shortly."
- `checkout.purchaseCompleteMessageKlarna` - "You'll pay in 4x interest-free. We'll send you a reminder a few days before each payment."
- `checkout.paymentFailed` - "Payment Failed"
- `checkout.paymentFailedMessage` - "Your payment could not be processed. Please try again."
- `checkout.tryAgain` - "Try Again"
- `checkout.goBack` - "Go Back"
- `checkout.processingPayment` - "Processing Payment"
- `checkout.processingPaymentMessage` - "Please complete your payment in Vipps..."
- `checkout.verifyingPayment` - "Verifying payment..."

### 📍 Address (Dirección)
- `address.shipping` - "Shipping Address"
- `address.billing` - "Billing Address"
- `address.firstName` - "First Name"
- `address.lastName` - "Last Name"
- `address.email` - "Email"
- `address.phone` - "Phone"
- `address.address` - "Address"
- `address.city` - "City"
- `address.state` - "State"
- `address.zip` - "ZIP"
- `address.country` - "Country"
- `address.phoneColon` - "Phone :"

### 💰 Payment (Pago)
- `payment.method` - "Payment method"
- `payment.selectMethod` - "Select a payment method to continue"
- `payment.noMethods` - "No payment methods available"
- `payment.schedule` - "Payment Schedule"
- `payment.downPaymentDueToday` - "Down payment due today"
- `payment.installment` - "Installment"
- `payment.payNext` - "Pay next"
- `payment.confirmWithKlarna` - "Confirm with Klarna"
- `payment.cancel` - "Cancel"
- `payment.klarnaCheckout` - "Klarna Checkout"
- `payment.connectingKlarna` - "Connecting with Klarna..."

### 🛍️ Product (Producto)
- `product.details` - "Details"
- `product.description` - "Description"
- `product.options` - "Options"
- `product.inStock` - "In Stock"
- `product.outOfStock` - "Out of Stock"
- `product.sku` - "SKU"
- `product.supplier` - "Supplier"
- `product.category` - "Category"
- `product.stock` - "Stock"
- `product.available` - "available"
- `product.noImage` - "No Image Available"

### 📦 Order (Pedido)
- `order.summary` - "Order Summary"
- `order.id` - "Order ID:"
- `order.review` - "Review Order"
- `order.reviewContent` - "Order review content..."
- `order.productSummary` - "Product Summary"
- `order.totalForItem` - "Total for this item:"
- `order.colors` - "Colors:"

### 🚚 Shipping (Envío)
- `shipping.options` - "Shipping Options"
- `shipping.required` - "Required"
- `shipping.noMethods` - "No shipping methods available for this order yet."
- `shipping.calculated` - "Shipping is calculated automatically for this order."
- `shipping.total` - "Total shipping"

### 🎫 Discount (Descuento)
- `discount.code` - "Discount Code"
- `discount.applied` - "Discount applied"
- `discount.removed` - "Discount removed"
- `discount.invalid` - "Invalid discount code"

### ✅ Validation (Validación)
- `validation.required` - "This field is required"
- `validation.invalidEmail` - "Please enter a valid email address"
- `validation.invalidPhone` - "Please enter a valid phone number"
- `validation.invalidAddress` - "Please enter a complete address"

### ❌ Errors (Errores)
- `error.network` - "Network error. Please check your connection."
- `error.server` - "Server error. Please try again later."
- `error.unknown` - "An unknown error occurred"
- `error.tryAgainLater` - "Please try again later"

## Idiomas Soportados

El SDK soporta cualquier código de idioma ISO 639-1 (2 letras). Los más comunes son:

- `en` - English
- `es` - Español
- `no` - Norsk (Norwegian)
- `sv` - Svenska (Swedish)
- `da` - Dansk (Danish)
- `fi` - Suomi (Finnish)
- `de` - Deutsch (German)
- `fr` - Français (French)
- `pt` - Português (Portuguese)
- `it` - Italiano (Italian)

## Ejemplo de Implementación en Kotlin

### Opción 1: Generar JSON desde Base de Datos

```kotlin
// TranslationEntity.kt
@Entity
data class TranslationEntity(
    @Id val id: String,
    val key: String,
    val language: String,
    val value: String
)

// TranslationRepository.kt
interface TranslationRepository {
    fun getTranslationsByLanguage(language: String): Map<String, String>
    fun getAllTranslations(): Map<String, Map<String, String>>
}

// TranslationService.kt
@Service
class TranslationService(
    private val repository: TranslationRepository
) {
    fun generateTranslationsJson(): String {
        val translations = repository.getAllTranslations()
        
        // Formato directo (recomendado) - sin wrapper "translations"
        val json = buildJsonObject {
            translations.forEach { (language, keys) ->
                put(language, buildJsonObject {
                    keys.forEach { (key, value) ->
                        put(key, value)
                    }
                })
            }
        }
        
        return json.toString()
    }
    
    // Alternativa: Formato con wrapper (también soportado)
    fun generateTranslationsJsonWithWrapper(): String {
        val translations = repository.getAllTranslations()
        
        val json = buildJsonObject {
            put("translations", buildJsonObject {
                translations.forEach { (language, keys) ->
                    put(language, buildJsonObject {
                        keys.forEach { (key, value) ->
                            put(key, value)
                        }
                    })
                }
            })
        }
        
        return json.toString()
    }
    
    fun generateTranslationsJsonForLanguage(language: String): String {
        val translations = repository.getTranslationsByLanguage(language)
        
        val json = buildJsonObject {
            put("translations", buildJsonObject {
                put(language, buildJsonObject {
                    translations.forEach { (key, value) ->
                        put(key, value)
                    }
                })
            })
        }
        
        return json.toString()
    }
}

// TranslationController.kt
@RestController
@RequestMapping("/api/translations")
class TranslationController(
    private val translationService: TranslationService
) {
    @GetMapping("/reachu-translations.json")
    fun getReachuTranslations(): ResponseEntity<String> {
        val json = translationService.generateTranslationsJson()
        return ResponseEntity.ok()
            .contentType(MediaType.APPLICATION_JSON)
            .body(json)
    }
}
```

### Opción 2: Leer desde Archivo de Recursos

```kotlin
// TranslationFileService.kt
@Service
class TranslationFileService {
    fun loadTranslationsFromFile(): Map<String, Map<String, String>> {
        val resource = this::class.java.getResourceAsStream("/translations/reachu-translations.json")
            ?: throw FileNotFoundException("reachu-translations.json not found")
        
        val json = Json.parseToJsonElement(resource.bufferedReader().readText())
        
        // Soporta ambos formatos: directo o con wrapper "translations"
        val translationsJson = json.jsonObject["translations"]?.jsonObject
            ?: json.jsonObject  // Si no hay wrapper, usar el objeto directamente
        
        return translationsJson.mapValues { (_, langJson) ->
            langJson.jsonObject.mapValues { (_, value) ->
                value.jsonPrimitive.content
            }
        }
    }
    
    /**
     * Filtra traducciones para excluir inglés (ya que está por defecto en el SDK)
     * Requiere pasar las traducciones como parámetro
     */
    fun generateTranslationsJsonWithoutEnglish(
        translations: Map<String, Map<String, String>>
    ): String {
        val filteredTranslations = translations.filterKeys { it != "en" }  // Excluir inglés
        
        val json = buildJsonObject {
            filteredTranslations.forEach { (language, keys) ->
                put(language, buildJsonObject {
                    keys.forEach { (key, value) ->
                        put(key, value)
                    }
                })
            }
        }
        
        return json.toString()
    }
    
    fun getTranslation(key: String, language: String): String? {
        val translations = loadTranslationsFromFile()
        return translations[language]?.get(key)
    }
}
```

### Opción 3: Endpoint para Actualizar Traducciones

```kotlin
// TranslationUpdateDto.kt
data class TranslationUpdateDto(
    val key: String,
    val language: String,
    val value: String
)

// TranslationController.kt
@RestController
@RequestMapping("/api/admin/translations")
class TranslationController(
    private val translationService: TranslationService
) {
    @PostMapping
    fun updateTranslation(@RequestBody dto: TranslationUpdateDto): ResponseEntity<TranslationEntity> {
        val updated = translationService.updateTranslation(dto.key, dto.language, dto.value)
        return ResponseEntity.ok(updated)
    }
    
    @PostMapping("/batch")
    fun updateTranslations(@RequestBody dtos: List<TranslationUpdateDto>): ResponseEntity<Map<String, TranslationEntity>> {
        val updated = translationService.updateTranslations(dtos)
        return ResponseEntity.ok(updated)
    }
    
    @PostMapping("/export")
    fun exportTranslations(): ResponseEntity<String> {
        val json = translationService.generateTranslationsJson()
        return ResponseEntity.ok()
            .contentType(MediaType.APPLICATION_JSON)
            .body(json)
    }
}
```

## Validación de Traducciones

### Verificar que Todas las Keys Existan

```kotlin
// TranslationValidator.kt
object TranslationValidator {
    private val REQUIRED_KEYS = setOf(
        // Common
        "common.addToCart", "common.remove", "common.close",
        // Cart
        "cart.title", "cart.empty", "cart.quantity",
        // Checkout
        "checkout.title", "checkout.proceed", "checkout.completePurchase",
        // ... todas las keys
    )
    
    fun validateTranslations(translations: Map<String, Map<String, String>>): ValidationResult {
        val missingKeys = mutableMapOf<String, MutableSet<String>>()
        
        translations.forEach { (language, keys) ->
            val missing = REQUIRED_KEYS.filter { it !in keys }
            if (missing.isNotEmpty()) {
                missingKeys[language] = missing.toMutableSet()
            }
        }
        
        return if (missingKeys.isEmpty()) {
            ValidationResult.Valid
        } else {
            ValidationResult.Invalid(missingKeys)
        }
    }
    
    sealed class ValidationResult {
        object Valid : ValidationResult()
        data class Invalid(val missingKeys: Map<String, Set<String>>) : ValidationResult()
    }
}
```

## Flujo de Trabajo Recomendado

### 1. Desarrollo Local
```bash
# 1. Actualizar traducciones en la base de datos o archivo
# 2. Generar JSON
POST /api/admin/translations/export

# 3. Copiar JSON a la app iOS
# Archivo: iOSApp/Configuration/reachu-translations.json
```

### 2. CI/CD Pipeline
```yaml
# .github/workflows/update-translations.yml
name: Update Translations

on:
  push:
    paths:
      - 'backend/translations/**'

jobs:
  update-translations:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Generate translations JSON
        run: |
          cd backend
          ./gradlew generateTranslationsJson
      - name: Update iOS translations file
        run: |
          cp backend/generated/reachu-translations.json \
             iOSApp/Configuration/reachu-translations.json
      - name: Commit changes
        run: |
          git config user.name "Translation Bot"
          git config user.email "bot@reachu.com"
          git add iOSApp/Configuration/reachu-translations.json
          git commit -m "Update translations from backend"
          git push
```

### 3. API Endpoint para App iOS

```kotlin
// TranslationApiController.kt
@RestController
@RequestMapping("/api/public/translations")
class TranslationApiController(
    private val translationService: TranslationService
) {
    @GetMapping("/reachu-translations.json")
    @Cacheable("translations")
    fun getTranslations(
        @RequestParam(required = false) languages: List<String>?
    ): ResponseEntity<String> {
        val translations = if (languages != null) {
            translationService.getTranslationsForLanguages(languages)
        } else {
            translationService.getAllTranslations()
        }
        
        // Formato directo (recomendado)
        val json = buildJsonObject {
            translations.forEach { (language, keys) ->
                put(language, buildJsonObject {
                    keys.forEach { (key, value) ->
                        put(key, value)
                    }
                })
            }
        }
        
        return ResponseEntity.ok()
            .header(HttpHeaders.CACHE_CONTROL, "public, max-age=3600")
            .contentType(MediaType.APPLICATION_JSON)
            .body(json.toString())
    }
}
```

## Buenas Prácticas

### ✅ DO
- Mantén todas las keys en un solo lugar (base de datos o archivo)
- Valida que todas las keys requeridas existan antes de exportar
- Usa códigos de idioma ISO 639-1 estándar
- Mantén consistencia en el formato de las keys (`category.key`)
- Documenta nuevas keys antes de agregarlas
- Versiona los cambios en las traducciones
- **Excluye traducciones en inglés** - El SDK tiene traducciones en inglés por defecto
- Usa el formato directo (sin wrapper "translations") para mejor compatibilidad
- Asegúrate de tener traducciones para los países que soportas

### ❌ DON'T
- No uses keys hardcodeadas directamente en el código Swift
- No mezcles idiomas en el mismo archivo de traducciones
- No uses caracteres especiales que puedan causar problemas en JSON
- No elimines keys que estén en uso sin verificar primero
- No traduzcas nombres propios o marcas
- **NO incluyas traducciones en inglés** - Están incluidas por defecto en el SDK
- No uses el wrapper "translations" si no es necesario (el formato directo es más simple)

## Estructura de Base de Datos Recomendada

```sql
CREATE TABLE translations (
    id VARCHAR(255) PRIMARY KEY,
    key VARCHAR(255) NOT NULL,
    language VARCHAR(2) NOT NULL,
    value TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_key_language (key, language),
    INDEX idx_language (language),
    INDEX idx_key (key)
);
```

## Ejemplo de Script de Migración

```kotlin
// TranslationMigration.kt
@Component
class TranslationMigration(
    private val repository: TranslationRepository
) {
    fun migrateTranslations() {
        // IMPORTANTE: NO incluir inglés - el SDK tiene traducciones por defecto
        val defaultTranslations = mapOf(
            "de" to mapOf(
                "cart.title" to "Warenkorb",
                "cart.empty" to "Ihr Warenkorb ist leer",
                "checkout.title" to "Zur Kasse",
                "common.addToCart" to "In den Warenkorb",
                "common.close" to "Schließen",
                // ... más traducciones alemanas
            ),
            "es" to mapOf(
                "cart.title" to "Carrito",
                "cart.empty" to "Tu carrito está vacío",
                "checkout.title" to "Checkout",
                "common.addToCart" to "Añadir al carrito",
                "common.close" to "Cerrar",
                // ... más traducciones españolas
            ),
            "no" to mapOf(
                "cart.title" to "Handlekurv",
                "cart.empty" to "Handlekurven din er tom",
                "checkout.title" to "Kasse",
                // ... más traducciones noruegas
            )
        )
        
        defaultTranslations.forEach { (language, keys) ->
            keys.forEach { (key, value) ->
                repository.save(
                    TranslationEntity(
                        id = "${key}_${language}",
                        key = key,
                        language = language,
                        value = value
                    )
                )
            }
        }
    }
    
    /**
     * Genera JSON para exportar a iOS (sin inglés)
     */
    fun exportForIOS(): String {
        val translations = repository.getAllTranslations()
            .filterKeys { it != "en" }  // Excluir inglés
        
        val json = buildJsonObject {
            translations.forEach { (language, keys) ->
                put(language, buildJsonObject {
                    keys.forEach { (key, value) ->
                        put(key, value)
                    }
                })
            }
        }
        
        return json.toString()
    }
}
```

## Sistema de Fallback

El SDK tiene un sistema inteligente de fallback para traducciones:

1. **Primera prioridad:** Idioma solicitado (ej: `de`)
2. **Segunda prioridad:** Idioma por defecto (`defaultLanguage` en config)
3. **Tercera prioridad:** Idioma de fallback (`fallbackLanguage` en config)
4. **Última prioridad:** Traducciones en inglés por defecto del SDK (`ReachuTranslationKey.defaultEnglish`)

**Ejemplo:**
- Usuario en Alemania → Idioma solicitado: `de`
- Si falta una traducción en `de` → Busca en `defaultLanguage`
- Si falta en `defaultLanguage` → Busca en `fallbackLanguage`
- Si falta en `fallbackLanguage` → Usa traducción en inglés del SDK

## Componentes Traducidos

Todos los componentes del SDK ahora usan traducciones:

- ✅ **RCheckoutOverlay** - Todo el flujo de checkout
- ✅ **RProductCard** - Botones, estados, mensajes
- ✅ **RProductDetailOverlay** - Detalles, opciones, especificaciones
- ✅ **RFloatingCartIndicator** - Indicador de carrito
- ✅ **RProductSlider** - Mensajes de carga y error

## Contacto y Soporte

Si necesitas agregar nuevas keys de traducción o tienes preguntas sobre el sistema:

1. Revisa el archivo `ReachuTranslationKey.swift` en el SDK (todas las keys disponibles)
2. Contacta al equipo de iOS para agregar nuevas keys
3. Sigue el formato: `category.key` (ej: `cart.title`, `checkout.proceed`)

## Checklist para Actualizar Traducciones

- [ ] Todas las keys requeridas están presentes
- [ ] Todos los idiomas soportados tienen traducciones (excepto inglés)
- [ ] **NO se incluyen traducciones en inglés** (están por defecto)
- [ ] El JSON es válido (usar JSON validator)
- [ ] Se ha usado el formato directo (sin wrapper "translations") si es posible
- [ ] Se han probado las traducciones en la app iOS
- [ ] Se ha verificado la detección automática de idioma por país
- [ ] Los cambios están documentados
- [ ] Se ha actualizado la versión del archivo si es necesario

---

# 📋 Sistema de Gestión de Campañas - Guía para Desarrolladores Kotlin

## Contexto

El Reachu SDK iOS incluye un sistema completo de gestión de campañas que permite controlar cuándo y cómo se muestran los componentes de compra (productos, banners, carritos, etc.) basándose en el ciclo de vida de la campaña.

### ¿Qué es una Campaña?

Una campaña es un período de tiempo durante el cual ciertos componentes del SDK pueden mostrarse en las apps iOS. Las campañas tienen:

- **`startDate`**: Fecha/hora de inicio (ISO 8601)
- **`endDate`**: Fecha/hora de fin (ISO 8601)
- **Componentes**: Banners, productos destacados, etc. que se muestran durante la campaña

### Estados de Campaña

1. **Upcoming** (Próxima): Antes de `startDate` - Los componentes NO se muestran
2. **Active** (Activa): Entre `startDate` y `endDate` - Los componentes se muestran normalmente
3. **Ended** (Terminada): Después de `endDate` - Todos los componentes se ocultan automáticamente

### Comportamiento del SDK

- **Si `campaignId` es 0 o no está configurado:** El SDK funciona normalmente sin restricciones
- **Si `campaignId > 0`:** El SDK respeta el ciclo de vida de la campaña y solo muestra componentes cuando la campaña está activa

## Tareas Requeridas del Backend Kotlin

### Tarea 1: Modelo de Datos de Campaña

**Paso 1.1:** Crear entidad `Campaign` en la base de datos

```kotlin
// CampaignEntity.kt
@Entity
@Table(name = "campaigns")
data class CampaignEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long,
    
    @Column(nullable = false)
    val name: String,
    
    @Column(name = "start_date", nullable = true)
    val startDate: Instant? = null,
    
    @Column(name = "end_date", nullable = true)
    val endDate: Instant? = null,
    
    @Column(name = "is_active")
    val isActive: Boolean = true,
    
    @Column(name = "created_at")
    val createdAt: Instant = Instant.now(),
    
    @Column(name = "updated_at")
    val updatedAt: Instant = Instant.now()
)
```

**Paso 1.2:** Crear DTOs para la API

```kotlin
// CampaignDto.kt
data class CampaignDto(
    val id: Long,
    val name: String,
    val startDate: String?,  // ISO 8601 format
    val endDate: String?      // ISO 8601 format
)

// ComponentDto.kt
data class ComponentDto(
    val id: String,
    val type: String,  // "banner", "offer_banner", "countdown", etc.
    val name: String,
    val config: Map<String, Any>,  // Dynamic config based on type
    val status: String? = null  // "active" or "inactive"
)

// ComponentConfigDto.kt (ejemplo para banner)
data class BannerConfigDto(
    val imageUrl: String,
    val title: String,
    val subtitle: String? = null,
    val ctaText: String? = null,
    val ctaLink: String? = null,
    val deeplink: String? = null
)

data class OfferBannerConfigDto(
    val logoUrl: String,
    val title: String,
    val subtitle: String? = null,
    val backgroundImageUrl: String,
    val countdownEndDate: String,  // ISO 8601
    val discountBadgeText: String,
    val ctaText: String,
    val ctaLink: String? = null,
    val deeplinkUrl: String? = null,
    val deeplinkAction: String? = null
)
```

### Tarea 2: Endpoint GET `/api/campaigns/{campaignId}`

**Paso 2.1:** Crear Repository

```kotlin
// CampaignRepository.kt
interface CampaignRepository : JpaRepository<CampaignEntity, Long> {
    fun findByIdAndIsActiveTrue(id: Long): CampaignEntity?
}
```

**Paso 2.2:** Crear Service

```kotlin
// CampaignService.kt
@Service
class CampaignService(
    private val campaignRepository: CampaignRepository
) {
    fun getCampaignById(id: Long): CampaignDto? {
        val campaign = campaignRepository.findByIdAndIsActiveTrue(id)
            ?: return null
        
        return CampaignDto(
            id = campaign.id,
            name = campaign.name,
            startDate = campaign.startDate?.toString(),
            endDate = campaign.endDate?.toString()
        )
    }
    
    fun getCampaignState(campaign: CampaignEntity): CampaignState {
        val now = Instant.now()
        
        // Si no hay fechas, campaña siempre activa
        if (campaign.startDate == null && campaign.endDate == null) {
            return CampaignState.ACTIVE
        }
        
        // Verificar si ha empezado
        if (campaign.startDate != null && now < campaign.startDate) {
            return CampaignState.UPCOMING
        }
        
        // Verificar si ha terminado
        if (campaign.endDate != null && now > campaign.endDate) {
            return CampaignState.ENDED
        }
        
        return CampaignState.ACTIVE
    }
    
    enum class CampaignState {
        UPCOMING, ACTIVE, ENDED
    }
}
```

**Paso 2.3:** Crear Controller

```kotlin
// CampaignController.kt
@RestController
@RequestMapping("/api/campaigns")
class CampaignController(
    private val campaignService: CampaignService
) {
    @GetMapping("/{campaignId}")
    fun getCampaign(@PathVariable campaignId: Long): ResponseEntity<CampaignDto> {
        val campaign = campaignService.getCampaignById(campaignId)
            ?: return ResponseEntity.notFound().build()
        
        return ResponseEntity.ok(campaign)
    }
}
```

**Respuesta esperada:**
```json
{
  "id": 10,
  "name": "Holiday Sale 2024",
  "startDate": "2024-12-25T10:00:00Z",
  "endDate": "2024-12-31T23:59:59Z"
}
```

### Tarea 3: Endpoint GET `/api/campaigns/{campaignId}/components`

**Paso 3.1:** Crear entidad `Component`

```kotlin
// ComponentEntity.kt
@Entity
@Table(name = "campaign_components")
data class ComponentEntity(
    @Id
    @Column(name = "component_id")
    val id: String,
    
    @Column(name = "campaign_id")
    val campaignId: Long,
    
    @Column(nullable = false)
    val type: String,  // "banner", "offer_banner", "countdown", etc.
    
    @Column(nullable = false)
    val name: String,
    
    @Column(columnDefinition = "TEXT")
    val config: String,  // JSON string
    
    @Column(nullable = false)
    val status: String = "inactive",  // "active" or "inactive"
    
    @Column(name = "activated_at", nullable = true)
    val activatedAt: Instant? = null,
    
    @Column(name = "created_at")
    val createdAt: Instant = Instant.now(),
    
    @Column(name = "updated_at")
    val updatedAt: Instant = Instant.now()
)
```

**Paso 3.2:** Crear Repository y Service

```kotlin
// ComponentRepository.kt
interface ComponentRepository : JpaRepository<ComponentEntity, String> {
    fun findByCampaignIdAndStatus(campaignId: Long, status: String): List<ComponentEntity>
}

// ComponentService.kt
@Service
class ComponentService(
    private val componentRepository: ComponentRepository,
    private val objectMapper: ObjectMapper
) {
    fun getActiveComponents(campaignId: Long): List<ComponentDto> {
        val components = componentRepository.findByCampaignIdAndStatus(campaignId, "active")
        
        return components.map { entity ->
            ComponentDto(
                id = entity.id,
                type = entity.type,
                name = entity.name,
                config = parseConfig(entity.config, entity.type),
                status = entity.status
            )
        }
    }
    
    private fun parseConfig(configJson: String, type: String): Map<String, Any> {
        return try {
            when (type) {
                "banner" -> objectMapper.readValue(configJson, BannerConfigDto::class.java)
                "offer_banner" -> objectMapper.readValue(configJson, OfferBannerConfigDto::class.java)
                else -> objectMapper.readValue(configJson, Map::class.java) as Map<String, Any>
            }
        } catch (e: Exception) {
            emptyMap()
        }
    }
}
```

**Paso 3.3:** Crear Controller

```kotlin
// CampaignController.kt (agregar método)
@GetMapping("/{campaignId}/components")
fun getCampaignComponents(@PathVariable campaignId: Long): ResponseEntity<List<ComponentDto>> {
    val components = componentService.getActiveComponents(campaignId)
    return ResponseEntity.ok(components)
}
```

**Respuesta esperada:**
```json
[
  {
    "id": "banner-abc123",
    "type": "banner",
    "name": "Welcome Banner",
    "status": "active",
    "config": {
      "imageUrl": "https://example.com/banner.jpg",
      "title": "Welcome!",
      "subtitle": "Check out our deals",
      "ctaText": "Shop Now",
      "ctaLink": "https://example.com/products"
    }
  },
  {
    "id": "offer-banner-xyz789",
    "type": "offer_banner",
    "name": "Holiday Offer",
    "status": "active",
    "config": {
      "logoUrl": "https://example.com/logo.png",
      "title": "Special Holiday Sale",
      "backgroundImageUrl": "https://example.com/bg.jpg",
      "countdownEndDate": "2024-12-31T23:59:59Z",
      "discountBadgeText": "50% OFF",
      "ctaText": "Shop Now",
      "ctaLink": "https://example.com/sale"
    }
  }
]
```

### Tarea 4: WebSocket Server para Eventos en Tiempo Real

**Paso 4.1:** Configurar WebSocket en Spring Boot

```kotlin
// WebSocketConfig.kt
@Configuration
@EnableWebSocket
class WebSocketConfig : WebSocketConfigurer {
    
    override fun registerWebSocketHandlers(registry: WebSocketHandlerRegistry) {
        registry.addHandler(CampaignWebSocketHandler(), "/ws/{campaignId}")
            .setAllowedOrigins("*")
    }
}

// CampaignWebSocketHandler.kt
@Component
class CampaignWebSocketHandler : TextWebSocketHandler() {
    
    private val sessions = ConcurrentHashMap<Long, MutableSet<WebSocketSession>>()
    
    override fun afterConnectionEstablished(session: WebSocketSession) {
        val campaignId = extractCampaignId(session)
        
        sessions.computeIfAbsent(campaignId) { mutableSetOf() }.add(session)
        
        // Si la campaña ya terminó, enviar evento inmediatamente
        val campaign = campaignService.getCampaignById(campaignId)
        if (campaign != null) {
            val state = campaignService.getCampaignState(campaign)
            if (state == CampaignState.ENDED) {
                sendMessage(session, CampaignEndedEvent(campaignId, campaign.endDate))
            }
        }
    }
    
    override fun afterConnectionClosed(session: WebSocketSession, status: CloseStatus) {
        val campaignId = extractCampaignId(session)
        sessions[campaignId]?.remove(session)
    }
    
    private fun extractCampaignId(session: WebSocketSession): Long {
        val uri = session.uri
        val pathSegments = uri.path.split("/")
        return pathSegments.last().toLong()
    }
    
    fun sendCampaignStarted(campaignId: Long, startDate: String?, endDate: String?) {
        val event = CampaignStartedEvent(campaignId, startDate, endDate)
        broadcastToCampaign(campaignId, event)
    }
    
    fun sendCampaignEnded(campaignId: Long, endDate: String?) {
        val event = CampaignEndedEvent(campaignId, endDate)
        broadcastToCampaign(campaignId, event)
    }
    
    fun sendComponentStatusChanged(campaignId: Long, componentId: String, status: String, component: ComponentDto?) {
        val event = ComponentStatusChangedEvent(campaignId, componentId, status, component)
        broadcastToCampaign(campaignId, event)
    }
    
    fun sendComponentConfigUpdated(campaignId: Long, componentId: String, component: ComponentDto) {
        val event = ComponentConfigUpdatedEvent(campaignId, componentId, component)
        broadcastToCampaign(campaignId, event)
    }
    
    private fun broadcastToCampaign(campaignId: Long, event: Any) {
        val campaignSessions = sessions[campaignId] ?: return
        
        val message = objectMapper.writeValueAsString(event)
        campaignSessions.forEach { session ->
            if (session.isOpen) {
                try {
                    session.sendMessage(TextMessage(message))
                } catch (e: Exception) {
                    // Handle error
                }
            }
        }
    }
}
```

**Paso 4.2:** Crear clases de eventos

```kotlin
// CampaignEvents.kt
data class CampaignStartedEvent(
    val type: String = "campaign_started",
    val campaignId: Long,
    val startDate: String?,
    val endDate: String?
)

data class CampaignEndedEvent(
    val type: String = "campaign_ended",
    val campaignId: Long,
    val endDate: String?
)

data class ComponentStatusChangedEvent(
    val type: String = "component_status_changed",
    val campaignId: Long,
    val componentId: String,
    val status: String,
    val component: ComponentDto? = null
)

data class ComponentConfigUpdatedEvent(
    val type: String = "component_config_updated",
    val campaignId: Long,
    val componentId: String,
    val component: ComponentDto
)
```

### Tarea 5: Scheduler para Eventos Automáticos

**Paso 5.1:** Crear scheduler que detecte cuando una campaña inicia o termina

```kotlin
// CampaignScheduler.kt
@Component
class CampaignScheduler(
    private val campaignRepository: CampaignRepository,
    private val campaignService: CampaignService,
    private val webSocketHandler: CampaignWebSocketHandler
) {
    
    @Scheduled(fixedRate = 60000) // Cada minuto
    fun checkCampaignLifecycle() {
        val campaigns = campaignRepository.findAll()
        
        campaigns.forEach { campaign ->
            val previousState = getCampaignState(campaign)
            val currentState = campaignService.getCampaignState(campaign)
            
            // Si cambió de upcoming a active
            if (previousState == CampaignState.UPCOMING && currentState == CampaignState.ACTIVE) {
                webSocketHandler.sendCampaignStarted(
                    campaign.id,
                    campaign.startDate?.toString(),
                    campaign.endDate?.toString()
                )
            }
            
            // Si cambió a ended
            if (previousState != CampaignState.ENDED && currentState == CampaignState.ENDED) {
                webSocketHandler.sendCampaignEnded(
                    campaign.id,
                    campaign.endDate?.toString()
                )
            }
            
            // Guardar estado actual
            saveCampaignState(campaign.id, currentState)
        }
    }
    
    private fun getCampaignState(campaign: CampaignEntity): CampaignState {
        // Implementar lógica para obtener estado previo (cache, Redis, etc.)
        // Por simplicidad, aquí solo verificamos el estado actual
        return campaignService.getCampaignState(campaign)
    }
    
    private fun saveCampaignState(campaignId: Long, state: CampaignState) {
        // Guardar estado en cache o Redis para comparar en la próxima ejecución
    }
}
```

**Paso 5.2:** Habilitar scheduling en la aplicación

```kotlin
// Application.kt
@SpringBootApplication
@EnableScheduling
class Application

fun main(args: Array<String>) {
    runApplication<Application>(*args)
}
```

### Tarea 6: Endpoints Admin para Gestionar Componentes

**Paso 6.1:** Crear endpoints para activar/desactivar componentes manualmente

```kotlin
// CampaignAdminController.kt
@RestController
@RequestMapping("/api/admin/campaigns")
class CampaignAdminController(
    private val componentService: ComponentService,
    private val webSocketHandler: CampaignWebSocketHandler
) {
    
    @PostMapping("/{campaignId}/components/{componentId}/activate")
    fun activateComponent(
        @PathVariable campaignId: Long,
        @PathVariable componentId: String
    ): ResponseEntity<ComponentDto> {
        val component = componentService.activateComponent(componentId)
        
        // Enviar evento WebSocket
        webSocketHandler.sendComponentStatusChanged(
            campaignId,
            componentId,
            "active",
            component
        )
        
        return ResponseEntity.ok(component)
    }
    
    @PostMapping("/{campaignId}/components/{componentId}/deactivate")
    fun deactivateComponent(
        @PathVariable campaignId: Long,
        @PathVariable componentId: String
    ): ResponseEntity<Void> {
        componentService.deactivateComponent(componentId)
        
        // Enviar evento WebSocket
        webSocketHandler.sendComponentStatusChanged(
            campaignId,
            componentId,
            "inactive",
            null
        )
        
        return ResponseEntity.ok().build()
    }
    
    @PutMapping("/{campaignId}/components/{componentId}")
    fun updateComponentConfig(
        @PathVariable campaignId: Long,
        @PathVariable componentId: String,
        @RequestBody config: Map<String, Any>
    ): ResponseEntity<ComponentDto> {
        val component = componentService.updateComponentConfig(componentId, config)
        
        // Enviar evento WebSocket
        webSocketHandler.sendComponentConfigUpdated(
            campaignId,
            componentId,
            component
        )
        
        return ResponseEntity.ok(component)
    }
}
```

## Checklist de Implementación

### Fase 1: Modelos y Base de Datos
- [ ] Crear tabla `campaigns` con campos: `id`, `name`, `start_date`, `end_date`, `is_active`
- [ ] Crear tabla `campaign_components` con campos: `component_id`, `campaign_id`, `type`, `name`, `config`, `status`
- [ ] Crear entidades JPA `CampaignEntity` y `ComponentEntity`
- [ ] Crear DTOs `CampaignDto` y `ComponentDto`
- [ ] Crear Repositories `CampaignRepository` y `ComponentRepository`

### Fase 2: Endpoints REST
- [ ] Implementar `GET /api/campaigns/{campaignId}` - Retorna información de la campaña
- [ ] Implementar `GET /api/campaigns/{campaignId}/components` - Retorna componentes activos
- [ ] Validar formato de fechas ISO 8601
- [ ] Manejar errores 404 cuando la campaña no existe
- [ ] Agregar tests unitarios para los endpoints

### Fase 3: WebSocket
- [ ] Configurar WebSocket en Spring Boot (`/ws/{campaignId}`)
- [ ] Implementar `CampaignWebSocketHandler`
- [ ] Implementar envío de eventos: `campaign_started`, `campaign_ended`, `component_status_changed`, `component_config_updated`
- [ ] Manejar desconexiones y reconexiones
- [ ] Enviar `campaign_ended` inmediatamente si la campaña ya terminó cuando se conecta un cliente

### Fase 4: Scheduler
- [ ] Crear `CampaignScheduler` que verifique campañas cada minuto
- [ ] Detectar transiciones de estado (upcoming → active, active → ended)
- [ ] Enviar eventos WebSocket automáticamente cuando cambia el estado
- [ ] Habilitar `@EnableScheduling` en la aplicación

### Fase 5: Endpoints Admin
- [ ] Implementar `POST /api/admin/campaigns/{campaignId}/components/{componentId}/activate`
- [ ] Implementar `POST /api/admin/campaigns/{campaignId}/components/{componentId}/deactivate`
- [ ] Implementar `PUT /api/admin/campaigns/{campaignId}/components/{componentId}`
- [ ] Enviar eventos WebSocket cuando se activan/desactivan componentes manualmente

### Fase 6: Validaciones y Tests
- [ ] Validar que `startDate` < `endDate` si ambos están presentes
- [ ] Validar formato de JSON en `config` de componentes
- [ ] Validar que solo un componente de cada tipo pueda estar activo a la vez
- [ ] Agregar tests de integración para WebSocket
- [ ] Agregar tests de integración para endpoints REST

## Ejemplo de Flujo Completo

### Escenario: Campaña Navideña

1. **Crear campaña en la base de datos:**
```sql
INSERT INTO campaigns (id, name, start_date, end_date, is_active)
VALUES (10, 'Holiday Sale 2024', '2024-12-25 10:00:00', '2024-12-31 23:59:59', true);
```

2. **Crear componente banner:**
```sql
INSERT INTO campaign_components (component_id, campaign_id, type, name, config, status)
VALUES (
  'banner-holiday-2024',
  10,
  'banner',
  'Holiday Banner',
  '{"imageUrl":"https://example.com/holiday.jpg","title":"Happy Holidays!","ctaText":"Shop Now"}',
  'inactive'
);
```

3. **Cuando llega `startDate` (25 dic 10:00):**
   - El scheduler detecta el cambio
   - Envía evento `campaign_started` vía WebSocket
   - El SDK iOS activa la campaña y carga componentes

4. **Admin activa el banner manualmente:**
   - `POST /api/admin/campaigns/10/components/banner-holiday-2024/activate`
   - Se envía evento `component_status_changed` con `status: "active"`
   - El SDK iOS muestra el banner inmediatamente

5. **Cuando llega `endDate` (31 dic 23:59):**
   - El scheduler detecta el cambio
   - Envía evento `campaign_ended` vía WebSocket
   - El SDK iOS oculta todos los componentes automáticamente

## Notas Importantes

1. **Un componente por tipo:** Solo un componente de cada tipo (`banner`, `offer_banner`, etc.) puede estar activo a la vez por campaña
2. **Fechas opcionales:** Si no hay `startDate` o `endDate`, la campaña se considera siempre activa
3. **WebSocket debe ser resiliente:** Manejar desconexiones y reconexiones automáticamente
4. **Formato de fechas:** Siempre usar ISO 8601 (`2024-12-25T10:00:00Z`)
5. **Config dinámico:** El campo `config` de componentes puede variar según el tipo, asegúrate de validar el formato JSON

