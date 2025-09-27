# 📱 Reachu SDK Demo App

Una aplicación iOS nativa que demuestra cómo usar el Reachu Swift SDK.

## 🚀 Instalación y Uso

### Prerrequisitos
- Xcode 15.0+
- iOS 15.0+

### Configuración

1. **Abrir el proyecto en Xcode:**
   ```bash
   open Demo/ReachuDemoApp/ReachuDemoApp.xcodeproj
   ```

2. **Agregar dependencia del SDK:**
   - En Xcode, selecciona el proyecto "ReachuDemoApp"
   - Ve a "Package Dependencies" 
   - Click "+" → "Add Local..."
   - Selecciona la carpeta raíz: `/Users/angelo/ReachuSwiftSDK`
   - Selecciona "ReachuDesignSystem"
   - Click "Add Package"

3. **Compilar y ejecutar:**
   ```
   Cmd+B  # Compilar
   Cmd+R  # Ejecutar en simulador
   ```

## 🎯 Funcionalidades

### ✅ Implementado
- **Design System Demo**: Colores, tipografía, botones y spacing del SDK
- **Navegación principal**: Con 4 secciones demo
- **SwiftUI Previews**: Para desarrollo iterativo

### 🚧 Próximamente  
- **Product Catalog**: Catálogo de productos con filtros
- **Shopping Cart**: Carrito funcional completo
- **Checkout Flow**: Flujo de checkout 3-pasos

## 🛠️ Desarrollo

Esta demo app consume el SDK como lo haría cualquier desarrollador externo:

```swift
import ReachuDesignSystem

// Usar componentes del SDK
RButton(title: "Add to Cart", style: .primary) {
    // Acción
}

// Usar tokens de diseño
Text("Title")
    .font(ReachuTypography.headline)
    .foregroundColor(ReachuColors.primary)
```

## 📱 Preview en Tiempo Real

Los cambios en el SDK se reflejan automáticamente en:
- SwiftUI Previews
- Simulador (rebuild automático)
- Dispositivos físicos

¡Perfecta para desarrollo iterativo del SDK! 🎨✨


---

## 🧪 Demos de Consola (Swift Package)

Estas demos viven dentro del paquete `ReachuSwiftSDK` y muestran, de forma puntual, cómo usar cada módulo del SDK. Se ejecutan como **ejecutables de SPM** (no son parte de la app iOS).

### 📂 Estructura

```
ReachuSwiftSDK/
  Demo/
    ReachuDemoSdk/
      CartDemo/         # Carrito: crear, agregar, shippings, etc.
      DiscountDemo/     # Descuentos: listar, crear, aplicar, remover, etc.
      MarketDemo/       # Mercados disponibles
      ChannelDemo/
        InfoDemo/       # Info del canal: términos y condiciones, channels
        CategoryDemo/   # Categorías
        ProductDemo/    # Productos (por id, sku, barcode, categoría, etc.)
      CheckoutDemo/     # Checkout: create, update, getById, (delete)
      PaymentDemo/      # Pagos: métodos, stripe, klarna, vipps
      Sdk/              # Orquestación/flow completo
    Utils/
      Logger.swift      # Helper para logs bonitos + JSON
```

> **Nota:** Todas las demos usan **datos quemados** (token, URL, productId, etc.) y el logger para imprimir **JSON** bonito. Ajusta los valores si ejecutas contra otro entorno.

### ▶️ Cómo ejecutar (CLI)

Desde la raíz del repo (`ReachuSwiftSDK/`):

```bash
swift build
swift run CartDemo
swift run DiscountDemo
swift run MarketDemo
swift run InfoDemo
swift run CategoryDemo
swift run ProductDemo
swift run CheckoutDemo
swift run PaymentDemo
swift run Sdk
```

### ▶️ Cómo ejecutar (Xcode)

1. Abre el paquete en Xcode (Archivo → **Open…** → `Package.swift`).
2. En el selector de **Scheme** (arriba a la izquierda) elige la demo que quieras (p. ej. **CartDemo**) y destino **My Mac**.
3. Corre con **⌘R**.  
4. Consola: **View → Debug Area → Activate Console** (⇧⌘Y).

> Si el Scheme no aparece: Product → **Scheme → Manage Schemes…** → marca **Show**.  
> Si Xcode se “traga” otros `main.swift`, ver **Problemas comunes** abajo.

---

## 📚 ¿Qué hace cada demo?

### 🛒 `CartDemo`
- **Crea** un cart (`create`).
- **Agrega** un item (`addItem`).
- Lee `getLineItemsBySupplier`, **elige el shipping más barato por supplier** y lo **aplica** a **cada `cart_item_id`** (`updateItem`).
- Re-consulta el cart.

```bash
swift run CartDemo
```

### 💸 `DiscountDemo`
- Lista **descuentos** (`get`) y **por canal** (`getByChannel`).
- **Crea** un descuento (`add`), **getById**, **verify (por code)**.
- **Aplica** el descuento a un cart (`apply`) y luego **lo remueve** (`deleteApplied`).
- (Opcional) **Borra** el descuento creado (`delete`).

```bash
swift run DiscountDemo
```

### 🌍 `MarketDemo`
- Lista **mercados disponibles** (`market.getAvailable()`).

```bash
swift run MarketDemo
```

### 🧭 `InfoDemo` (Channel → Info)
- **Channels** (`getChannels`).
- **Purchase Conditions** (`getPurchaseConditions`).
- **Terms & Conditions** (`getTermsAndConditions`).

```bash
swift run InfoDemo
```

### 🧩 `CategoryDemo` (Channel → Categorías)
- Lista **categorías** (`category.get()`).

```bash
swift run CategoryDemo
```

### 📦 `ProductDemo` (Channel → Productos)
- **getByParams** (por `productId`, `sku` o `barcode`) usando la **query unificada** `GET_PRODUCTS_CHANNEL_QUERY` (la respuesta es un **array**; se toma el **primer elemento** si la API requiere un solo producto).
- **getByIds** y **get** (con filtros).
- **getByCategoryId / getByCategoryIds**.
- **getBySkus / getByBarcodes**.

```bash
swift run ProductDemo
```

### 🧾 `CheckoutDemo`
- **Crea** checkout desde `cart_id` (`create`).
- **Actualiza** checkout (`update`) con:
  - `email`, `success_url`, `cancel_url`, `payment_method` (opcional)
  - `shipping_address` y `billing_address` con **claves snake_case** (paridad con Flutter)
  - Banderas: `buyer_accepts_terms_conditions` y `buyer_accepts_purchase_conditions`
- **getById** y (opcional) **delete**.

```bash
swift run CheckoutDemo
```

### 💳 `PaymentDemo`
- **getAvailableMethods**
- **Stripe**: `stripeIntent` (opcional `returnEphemeralKey`) y `stripeLink` (platform builder).
- **Klarna**: `klarnaInit(countryCode:href:email:)`
- **Vipps**: `vippsInit(email:returnUrl:)`

```bash
swift run PaymentDemo
```

### 🧭 `Sdk` (flujo completo)
- Orquesta un **happy path** combinando módulos (cart → shipping → checkout → discount → payment).

```bash
swift run Sdk
```

---

## 🧰 Problemas comunes (Troubleshooting)

**`'@main' attribute cannot be used in a module that contains top-level code'`**  
- Asegúrate de que **cada demo** tenga **un solo** `main.swift`.  
- Si anidas subdemos (p. ej., `ChannelDemo/CategoryDemo`), en el target padre usa `exclude: [...]`.  
- Puedes fijar `sources: ["main.swift"]` en el target de la demo para compilar **solo** ese archivo.

**El Scheme corre `ReachuSwiftSDK-Package` en vez de la demo**  
- Product → Scheme → **Edit Scheme… → Build**: deja **solo** la fila con icono **▸** de tu demo.  
- Limpia: **Product → Clean Build Folder** (⇧⌘K).

**SwiftPM advierte: “Source files for target X should be under Sources/X…”**  
- Declara `path:` correcto en `Package.swift` (p. ej. `Demo/ReachuDemoSdk/CartDemo`).  
- Si la carpeta está vacía o sin `main.swift`, añade el archivo o elimina el target hasta tenerlo.

**Cambios no se reflejan**  
- `swift package reset && swift build` o en Xcode: **Reset Package Caches** + **Resolve Package Versions**.
