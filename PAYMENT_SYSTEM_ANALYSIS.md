# 📊 Análisis Profundo del Sistema de Pagos - ReachuSwiftSDK

## 🎯 Executive Summary

El sistema actual de pagos tiene **dos flujos paralelos** que necesitan consolidarse:
1. **Flujo Backend (Reachu)**: Stripe + Klarna a través del backend de Reachu
2. **Flujo Directo**: Klarna directo con credenciales hardcodeadas

**PROBLEMA CRÍTICO**: Las credenciales de Klarna están hardcodeadas en el SDK, lo cual es:
- ❌ **Inseguro** (credenciales expuestas en el código)
- ❌ **Inflexible** (no permite multi-tenant)
- ❌ **Inconsistente** (Stripe usa backend, Klarna usa directo)

---

## 📁 Estructura Actual

### 1. **RCheckoutOverlay.swift** (Componente Principal)
**Ubicación**: `/Sources/ReachuUI/Components/RCheckoutOverlay.swift`

#### Estado Actual de Pagos:
```swift
// Payment Information
@State private var selectedPaymentMethod: PaymentMethod = .stripe
@State private var acceptsTerms = true
@State private var acceptsPurchaseConditions = true

// Stripe (iOS)
#if os(iOS)
    @State private var paymentSheet: PaymentSheet?
    @State private var shouldPresentStripeSheet = false
#endif

// Klarna (iOS + KlarnaMobileSDK)
#if os(iOS) && canImport(KlarnaMobileSDK)
    // Flujo backend (ORIGINAL - Ya no se usa)
    @State private var showKlarnaNativeSheet = false
    @State private var klarnaNativeInitData: InitPaymentKlarnaNativeDto?
    @State private var klarnaAvailableCategories: [KlarnaNativePaymentMethodCategoryDto] = []
    @State private var klarnaSelectedCategoryIdentifier: String = ""
    
    // Flujo directo (NUEVO - En uso actualmente)
    @State private var isUsingKlarnaDirectFlow = true // ⚠️ Siempre true
    @State private var klarnaDirectService: KlarnaAPIService? // ⚠️ Credenciales hardcodeadas
    @State private var klarnaDirectAmount: Int = 0
    @State private var klarnaDirectProductName: String = "iPhone 15 Pro Max"
    @State private var klarnaAutoAuthorize = false
    @State private var showKlarnaErrorToast = false
    @State private var klarnaErrorMessage = ""
#endif
```

**Análisis**:
- ✅ **Stripe**: Usa flujo backend correcto (`prepareStripePaymentSheet()`)
- ❌ **Klarna**: Usa flujo directo con `KlarnaAPIService` (credenciales hardcodeadas)
- ⚠️ **Dual State**: Mantiene estado para ambos flujos (backend + directo)
- ⚠️ **Inconsistencia**: Un método usa backend, otro usa directo

---

### 2. **KlarnaAPIService.swift** (Servicio Directo)
**Ubicación**: `/Sources/ReachuUI/Services/KlarnaAPIService.swift`

#### Credenciales Hardcodeadas:
```swift
final class KlarnaAPIService {
    // MARK: - Credentials ⚠️ PROBLEMA CRÍTICO
    
    private let username = "f4db48cb-b9a8-4933-abbe-39a9fadcd12f"
    private let password = "klarna_live_api_VWtxaE5QTzBZKlZ6bylnRDZ5SWpyaFZqU1QlKXl0U20..."
    private let baseURL = "https://api.klarna.com"
    
    // MARK: - API Methods
    
    func createSession(
        country: String = "US",
        currency: String = "USD",
        locale: String = "en-US",
        amount: Int = 5000,
        productName: String = "Test Product"
    ) async throws -> CreateSessionResponse { /* ... */ }
    
    func createOrder(
        authorizationToken: String,
        country: String = "US",
        currency: String = "USD",
        locale: String = "en-US",
        amount: Int = 5000,
        productName: String = "Test Product"
    ) async throws -> CreateOrderResponse { /* ... */ }
}
```

**Problemas**:
1. ❌ **Seguridad**: Credenciales de producción en código fuente
2. ❌ **Single-Tenant**: Solo funciona para una cuenta de Klarna
3. ❌ **No escalable**: Cada cliente necesitaría recompilar el SDK
4. ❌ **Violación de PCI DSS**: Credenciales de pago en cliente
5. ❌ **Repositorio público**: Las credenciales están en GitHub

---

### 3. **PaymentModule.swift** (Backend - Correcto pero no usado para Klarna)
**Ubicación**: `/Sources/ReachuCore/Sdk/Modules/PaymentModule.swift`

#### Métodos Disponibles:
```swift
// ✅ STRIPE - Usado correctamente
public func stripeIntent(
    checkoutId: String,
    returnEphemeralKey: Bool = false
) async throws -> PaymentIntentStripeDto {
    // Llama al backend de Reachu
    // Backend retorna: client_secret, customer, publishable_key, ephemeral_key
}

// ✅ KLARNA NATIVE - Existe pero NO se usa actualmente
public func klarnaInit(
    checkoutId: String,
    countryCode: String,
    href: String,
    email: String?
) async throws -> InitPaymentKlarnaDto {
    // Llama al backend de Reachu
    // Backend retorna: order_id, status, locale, html_snippet
}

// ✅ KLARNA NATIVE INIT - Existe y se usaba antes
public func initKlarnaNative(
    input: KlarnaNativeInitInputDto
) async throws -> InitPaymentKlarnaNativeDto {
    // Llama al backend de Reachu
    // Backend retorna: client_token, session_id, payment_method_categories
}

// ✅ KLARNA NATIVE CONFIRM - Existe pero NO se usa
public func confirmKlarnaNative(
    checkoutId: String,
    authorizationToken: String,
    /* ... */
) async throws -> ConfirmPaymentKlarnaDto {
    // Confirma el pago en el backend
}
```

**Análisis**:
- ✅ El backend **YA TIENE** todos los métodos necesarios para Klarna
- ✅ El backend **maneja las credenciales de forma segura**
- ❌ `RCheckoutOverlay` **NO usa estos métodos** actualmente para Klarna
- ❌ Se creó `KlarnaAPIService` para bypass el backend

---

### 4. **PaymentGraphQL.swift** (Queries & Mutations)
**Ubicación**: `/Sources/ReachuCore/Sdk/Core/Operations/PaymentGraphQL.swift`

#### Queries Disponibles:
```graphql
# ✅ Obtener métodos de pago disponibles (incluyendo publishableKey)
query GetAvailablePaymentMethods {
  Payment {
    GetAvailablePaymentMethods {
      name              # "Stripe", "Klarna", etc.
      publishableKey    # Clave pública del provider
    }
  }
}

# ✅ Crear Payment Intent de Stripe
mutation CreatePaymentIntentStripe($checkoutId: String!, $returnEphemeralKey: Boolean) {
  Payment {
    CreatePaymentIntentStripe(checkout_id: $checkoutId, return_ephemeral_key: $returnEphemeralKey) {
      client_secret
      customer
      publishable_key    # ✅ Viene del backend
      ephemeral_key
    }
  }
}

# ✅ Inicializar Klarna Native
mutation CreatePaymentKlarnaNative(
  $checkoutId: String!
  $countryCode: String
  $currency: String
  $locale: String
  $returnUrl: String
  # ... otros campos ...
) {
  Payment {
    CreatePaymentKlarnaNative(/* ... */) {
      cart_id
      checkout_id
      client_token           # ✅ Token de sesión de Klarna
      purchase_country
      purchase_currency
      session_id
      payment_method_categories {
        identifier
        name
        asset_urls {
          descriptive
          standard
        }
      }
    }
  }
}

# ✅ Confirmar Klarna Native
mutation ConfirmPaymentKlarnaNative(
  $checkoutId: String!
  $authorizationToken: String!
  # ... otros campos ...
) {
  Payment {
    ConfirmPaymentKlarnaNative(/* ... */) {
      order_id
      checkout_id
      fraud_status
      order { /* ... */ }
    }
  }
}
```

**Análisis**:
- ✅ **Backend completo**: Todas las operaciones necesarias existen
- ✅ **Seguridad**: Las credenciales nunca se exponen al cliente
- ✅ **Multi-tenant**: Cada merchant tiene sus propias credenciales en el backend

---

## 🔄 Flujo Actual vs. Flujo Correcto

### 📍 Flujo Actual (Stripe) - ✅ CORRECTO
```
Usuario presiona "Initiate Payment"
    ↓
RCheckoutOverlay.prepareStripePaymentSheet()
    ↓
CartManager.stripeIntent(checkoutId)
    ↓
Backend Reachu → Stripe API
    ↓ (client_secret + publishable_key)
PaymentSheet configurado
    ↓
Usuario completa pago en Stripe UI
    ↓
Backend procesa webhook de Stripe
    ↓
Orden creada
```

**Por qué funciona bien**:
1. ✅ Credenciales en backend (seguro)
2. ✅ Multi-tenant (cada cliente sus keys)
3. ✅ Webhooks manejados por backend
4. ✅ PCI DSS compliant

---

### 📍 Flujo Actual (Klarna) - ❌ INCORRECTO
```
Usuario presiona "Initiate Payment"
    ↓
RCheckoutOverlay.initiateKlarnaDirectFlow()
    ↓
KlarnaAPIService (credenciales hardcodeadas)
    ↓
Klarna API directo
    ↓ (client_token)
HiddenKlarnaAutoAuthorize creado
    ↓
Usuario completa pago en Klarna UI
    ↓
KlarnaAPIService.createOrder() ⚠️ (Directo, sin backend)
    ↓
Orden creada ⚠️ (Backend de Reachu no lo sabe)
```

**Problemas**:
1. ❌ Credenciales hardcodeadas (inseguro)
2. ❌ Bypass del backend (sin tracking)
3. ❌ No hay webhooks manejados
4. ❌ Backend no sabe que se creó una orden
5. ❌ Solo funciona para una cuenta de Klarna

---

### 📍 Flujo Correcto (Klarna) - ✅ PROPUESTO
```
Usuario presiona "Initiate Payment"
    ↓
RCheckoutOverlay.prepareKlarnaPaymentSheet()
    ↓
CartManager.initKlarnaNative(input: KlarnaNativeInitInputDto)
    ↓
Backend Reachu → Klarna API (con credenciales del merchant)
    ↓ (client_token + session_id + payment_method_categories)
KlarnaNativePaymentSheet o HiddenKlarnaAutoAuthorize
    ↓
Usuario completa pago en Klarna UI
    ↓ (authorizationToken)
CartManager.confirmKlarnaNative(checkoutId, authorizationToken)
    ↓
Backend Reachu → Klarna API (confirmar orden)
    ↓
Orden creada en Reachu + Klarna
    ↓
Webhooks manejados por backend
```

**Ventajas**:
1. ✅ Credenciales en backend (seguro)
2. ✅ Multi-tenant (cada cliente sus keys)
3. ✅ Backend trackea toda la transacción
4. ✅ Webhooks manejados correctamente
5. ✅ Consistente con flujo de Stripe

---

## 🏗️ Arquitectura Propuesta

### 1. **Unificar Flujos de Pago**

#### Crear `PaymentCoordinator` (Nuevo)
```swift
@available(iOS 15.0, *)
final class PaymentCoordinator: ObservableObject {
    private let cartManager: CartManager
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Stripe
    
    func prepareStripePayment(checkoutId: String) async -> StripePaymentConfig? {
        do {
            let dto = try await cartManager.stripeIntent(
                checkoutId: checkoutId,
                returnEphemeralKey: true
            )
            return StripePaymentConfig(
                clientSecret: dto.clientSecret,
                publishableKey: dto.publishableKey,
                customerId: dto.customer,
                ephemeralKey: dto.ephemeralKey
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Klarna Native
    
    func prepareKlarnaPayment(
        checkoutId: String,
        customer: KlarnaNativeCustomerInputDto,
        shippingAddress: KlarnaNativeAddressInputDto,
        billingAddress: KlarnaNativeAddressInputDto,
        returnUrl: String
    ) async -> KlarnaPaymentConfig? {
        do {
            let input = KlarnaNativeInitInputDto(
                countryCode: shippingAddress.country,
                currency: cartManager.currency,
                locale: getLocale(for: shippingAddress.country),
                returnUrl: returnUrl,
                intent: "buy",
                autoCapture: true,
                customer: customer,
                billingAddress: billingAddress,
                shippingAddress: shippingAddress
            )
            
            let dto = try await cartManager.initKlarnaNative(input: input)
            
            return KlarnaPaymentConfig(
                clientToken: dto.clientToken,
                sessionId: dto.sessionId,
                paymentMethodCategories: dto.paymentMethodCategories ?? [],
                returnUrl: returnUrl
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    func confirmKlarnaPayment(
        checkoutId: String,
        authorizationToken: String,
        customer: KlarnaNativeCustomerInputDto,
        shippingAddress: KlarnaNativeAddressInputDto,
        billingAddress: KlarnaNativeAddressInputDto
    ) async -> KlarnaOrderResult? {
        do {
            let dto = try await cartManager.confirmKlarnaNative(
                checkoutId: checkoutId,
                authorizationToken: authorizationToken,
                autoCapture: true,
                customer: customer,
                billingAddress: billingAddress,
                shippingAddress: shippingAddress
            )
            
            return KlarnaOrderResult(
                orderId: dto.orderId,
                checkoutId: dto.checkoutId,
                fraudStatus: dto.fraudStatus
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}

// MARK: - Configuration Models

struct StripePaymentConfig {
    let clientSecret: String
    let publishableKey: String
    let customerId: String
    let ephemeralKey: String?
}

struct KlarnaPaymentConfig {
    let clientToken: String
    let sessionId: String
    let paymentMethodCategories: [KlarnaNativePaymentMethodCategoryDto]
    let returnUrl: String
}

struct KlarnaOrderResult {
    let orderId: String
    let checkoutId: String
    let fraudStatus: String
}
```

---

### 2. **Simplificar RCheckoutOverlay**

#### Remover Estado Duplicado:
```swift
// ❌ REMOVER
@State private var isUsingKlarnaDirectFlow = true
@State private var klarnaDirectService: KlarnaAPIService?
@State private var klarnaDirectAmount: Int = 0
@State private var klarnaDirectProductName: String = "iPhone 15 Pro Max"
@State private var klarnaDirectStatusMessage: String?

// ✅ MANTENER (simplificado)
@State private var klarnaPaymentConfig: KlarnaPaymentConfig?
@State private var klarnaAutoAuthorize = false
@State private var showKlarnaErrorToast = false
@State private var klarnaErrorMessage = ""
```

#### Usar PaymentCoordinator:
```swift
@StateObject private var paymentCoordinator = PaymentCoordinator()

// En el botón "Initiate Payment"
if selectedPaymentMethod == .klarna {
    isLoading = true
    let config = await paymentCoordinator.prepareKlarnaPayment(
        checkoutId: cartManager.checkoutId,
        customer: buildCustomer(),
        shippingAddress: buildShippingAddress(),
        billingAddress: buildBillingAddress(),
        returnUrl: klarnaSuccessURLString
    )
    isLoading = false
    
    if let config = config {
        klarnaPaymentConfig = config
        klarnaAutoAuthorize = true
    } else {
        errorMessage = paymentCoordinator.errorMessage
        checkoutStep = .error
    }
    return
}
```

#### En el callback de autorización:
```swift
onAuthorized: { authToken, finalizeRequired in
    Task { @MainActor in
        isLoading = true
        
        let result = await paymentCoordinator.confirmKlarnaPayment(
            checkoutId: cartManager.checkoutId,
            authorizationToken: authToken,
            customer: buildCustomer(),
            shippingAddress: buildShippingAddress(),
            billingAddress: buildBillingAddress()
        )
        
        isLoading = false
        
        if let result = result {
            checkoutStep = .success
            print("✅ Order created: \(result.orderId), Fraud: \(result.fraudStatus)")
        } else {
            errorMessage = paymentCoordinator.errorMessage
            checkoutStep = .error
        }
    }
}
```

---

### 3. **Eliminar KlarnaAPIService**

```swift
// ❌ BORRAR ARCHIVO COMPLETO
// /Sources/ReachuUI/Services/KlarnaAPIService.swift
```

**Razón**: Ya no es necesario. El backend maneja todo.

---

### 4. **Backend: Configuración Dinámica de Credenciales**

#### En el Backend de Reachu:

```typescript
// merchants_payment_config
{
  merchant_id: "merchant_123",
  payment_methods: {
    stripe: {
      publishable_key: "pk_live_...",
      secret_key: "sk_live_...",  // Solo en backend
      webhook_secret: "whsec_..."  // Solo en backend
    },
    klarna: {
      username: "merchant_klarna_user",
      password: "klarna_live_api_...",  // Solo en backend
      environment: "production",  // o "playground"
      region: "eu"  // "eu", "na", "oc"
    }
  }
}
```

#### Endpoint `GetAvailablePaymentMethods`:
```graphql
query GetAvailablePaymentMethods {
  Payment {
    GetAvailablePaymentMethods {
      name              # "Stripe", "Klarna", "Vipps"
      publishableKey    # Solo para Stripe (clave pública)
      # NO retornar claves privadas de Klarna
    }
  }
}
```

**Respuesta**:
```json
[
  {
    "name": "Stripe",
    "publishableKey": "pk_live_..."
  },
  {
    "name": "Klarna",
    "publishableKey": null  // Klarna no usa publishable key en cliente
  }
]
```

---

## 📋 Plan de Migración

### Fase 1: Preparación (Backend) 🔧
1. ✅ Verificar que `CreatePaymentKlarnaNative` mutation funciona
2. ✅ Verificar que `ConfirmPaymentKlarnaNative` mutation funciona
3. ✅ Agregar configuración por merchant para credenciales de Klarna
4. ✅ Configurar webhooks de Klarna en backend

### Fase 2: SDK - Refactoring 🔨
1. ✅ Crear `PaymentCoordinator` en `/Sources/ReachuUI/Coordinators/`
2. ✅ Agregar `StripePaymentConfig` y `KlarnaPaymentConfig` structs
3. ✅ Implementar `prepareKlarnaPayment()` en `PaymentCoordinator`
4. ✅ Implementar `confirmKlarnaPayment()` en `PaymentCoordinator`

### Fase 3: RCheckoutOverlay - Limpieza 🧹
1. ✅ Agregar `@StateObject private var paymentCoordinator`
2. ✅ Remover estado de `klarnaDirectService`, `klarnaDirectAmount`, etc.
3. ✅ Reemplazar `initiateKlarnaDirectFlow()` con `paymentCoordinator.prepareKlarnaPayment()`
4. ✅ Actualizar callback `onAuthorized` para usar `confirmKlarnaPayment()`
5. ✅ Remover `isUsingKlarnaDirectFlow` (siempre usar backend)

### Fase 4: Limpieza Final 🗑️
1. ✅ Eliminar `/Sources/ReachuUI/Services/KlarnaAPIService.swift`
2. ✅ Eliminar función `prepareKlarnaNative()` antigua (opcional, por compatibilidad)
3. ✅ Actualizar tests
4. ✅ Actualizar documentación

### Fase 5: Testing 🧪
1. ✅ Probar flujo de Stripe (debe seguir funcionando)
2. ✅ Probar flujo de Klarna con backend
3. ✅ Probar múltiples merchants (credenciales diferentes)
4. ✅ Probar manejo de errores
5. ✅ Probar webhooks

---

## ⚠️ Consideraciones de Seguridad

### Problemas Actuales:
1. ❌ **Credenciales en código fuente**
   - `username` y `password` de Klarna en `KlarnaAPIService.swift`
   - Expuestos en repositorio público de GitHub
   - Visibles en binario compilado (.ipa)

2. ❌ **PCI DSS Compliance**
   - Credenciales de pago no deben estar en cliente
   - Solo claves públicas permitidas en frontend
   - Violación de normas de seguridad de pagos

3. ❌ **Single-Tenant**
   - Solo funciona para una cuenta de Klarna
   - No permite onboarding de nuevos merchants

### Solución:
1. ✅ **Credenciales solo en backend**
   - Almacenar en base de datos encriptada
   - Variables de entorno para producción
   - Acceso restringido por merchant_id

2. ✅ **Zero Trust en Cliente**
   - Cliente solo recibe `client_token` temporal
   - Cliente solo envía `authorization_token`
   - Backend valida todo con Klarna API

3. ✅ **Multi-Tenant Seguro**
   - Cada merchant sus propias credenciales
   - Aislamiento total entre merchants
   - Auditoría de acceso a credenciales

---

## 📊 Comparación de Flujos

| Aspecto | Stripe (Actual) | Klarna (Actual) | Klarna (Propuesto) |
|---------|----------------|-----------------|-------------------|
| **Credenciales** | ✅ Backend | ❌ Hardcoded | ✅ Backend |
| **Multi-Tenant** | ✅ Sí | ❌ No | ✅ Sí |
| **Seguridad** | ✅ PCI DSS | ❌ Inseguro | ✅ PCI DSS |
| **Webhooks** | ✅ Backend | ❌ No | ✅ Backend |
| **Tracking** | ✅ Completo | ❌ Parcial | ✅ Completo |
| **Consistencia** | ✅ Buena | ❌ Mala | ✅ Buena |

---

## 🎯 Recomendaciones Finales

### Prioridad Alta 🔴
1. **Migrar Klarna a backend INMEDIATAMENTE**
   - Razón: Seguridad crítica
   - Tiempo estimado: 2-3 días

2. **Eliminar KlarnaAPIService**
   - Razón: Credenciales expuestas
   - Tiempo estimado: 1 día

3. **Rotar credenciales de Klarna**
   - Razón: Ya están comprometidas (en GitHub)
   - Tiempo estimado: 1 hora

### Prioridad Media 🟡
4. **Crear PaymentCoordinator**
   - Razón: Mejor arquitectura, más mantenible
   - Tiempo estimado: 2 días

5. **Unificar estado en RCheckoutOverlay**
   - Razón: Reducir complejidad
   - Tiempo estimado: 1 día

### Prioridad Baja 🟢
6. **Agregar analytics de pagos**
   - Track success rate por método
   - Tiempo promedio de checkout
   - Errores más comunes

7. **Mejorar error handling**
   - Mensajes más específicos
   - Retry automático en fallos de red
   - Logging detallado

---

## 📝 Checklist de Implementación

### Backend
- [ ] Verificar mutation `CreatePaymentKlarnaNative` funciona
- [ ] Verificar mutation `ConfirmPaymentKlarnaNative` funciona
- [ ] Agregar tabla de configuración de credenciales por merchant
- [ ] Configurar webhooks de Klarna
- [ ] Implementar rotación de credenciales

### SDK
- [ ] Crear `PaymentCoordinator.swift`
- [ ] Implementar `prepareKlarnaPayment()`
- [ ] Implementar `confirmKlarnaPayment()`
- [ ] Actualizar `RCheckoutOverlay` para usar coordinator
- [ ] Eliminar `KlarnaAPIService.swift`
- [ ] Eliminar estado duplicado
- [ ] Actualizar tests

### Testing
- [ ] Unit tests para `PaymentCoordinator`
- [ ] Integration tests para flujo de Stripe
- [ ] Integration tests para flujo de Klarna
- [ ] End-to-end test de checkout completo
- [ ] Test de múltiples merchants

### Documentación
- [ ] Actualizar README con nuevo flujo
- [ ] Documentar configuración de merchants
- [ ] Agregar diagramas de arquitectura
- [ ] Guía de migración para clientes existentes

### Seguridad
- [ ] Rotar credenciales de Klarna comprometidas
- [ ] Audit de código para otras credenciales hardcodeadas
- [ ] Implementar secrets scanning en CI/CD
- [ ] Configurar alertas de seguridad

---

## 🔗 Referencias

### Documentación Oficial
- [Klarna Payments API](https://docs.klarna.com/klarna-payments/)
- [Klarna iOS SDK](https://docs.klarna.com/klarna-payments/in-app/ios-sdk/)
- [Stripe iOS SDK](https://stripe.com/docs/payments/accept-a-payment?platform=ios)
- [PCI DSS Requirements](https://www.pcisecuritystandards.org/)

### Archivos Relevantes
- `/Sources/ReachuUI/Components/RCheckoutOverlay.swift` (líneas 57-73, 605-608, 1284-1387)
- `/Sources/ReachuUI/Services/KlarnaAPIService.swift` (TODO EL ARCHIVO - ELIMINAR)
- `/Sources/ReachuCore/Sdk/Modules/PaymentModule.swift` (líneas 103-163)
- `/Sources/ReachuCore/Sdk/Core/Operations/PaymentGraphQL.swift` (líneas 70-162)

---

**Fecha**: 2025-01-10  
**Autor**: AI Assistant  
**Versión**: 1.0

