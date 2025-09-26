# Reachu Swift SDK

A native Swift SDK for integrating Reachu's commerce platform into iOS/macOS apps and Swift services.  
It includes production‑ready repositories, typed models, a tiny GraphQL client, and a set of runnable console demos that exercise end‑to‑end flows (cart, discounts, checkout, and payments).

---

## Table of Contents

- [Reachu Swift SDK](#reachu-swift-sdk)
  - [Table of Contents](#table-of-contents)
  - [Requirements](#requirements)
  - [Installation](#installation)
    - [Add as a Swift Package (local)](#add-as-a-swift-package-local)
    - [Add as a Swift Package (remote)](#add-as-a-swift-package-remote)
  - [Architecture](#architecture)
  - [Quickstart](#quickstart)
  - [Core Flows](#core-flows)
    - [Cart (create → add item → shipping → checkout)](#cart-create--add-item--shipping--checkout)
    - [Discounts](#discounts)
    - [Checkout (update keys parity)](#checkout-update-keys-parity)
    - [Payments (Stripe / Klarna / Vipps)](#payments-stripe--klarna--vipps)
    - [Products (unified query)](#products-unified-query)
    - [Channel Info \& Categories](#channel-info--categories)
    - [Markets](#markets)
  - [Console Demos](#console-demos)
  - [Project Layout](#project-layout)
  - [Troubleshooting](#troubleshooting)
  - [License](#license)

---

## Requirements

- Xcode **15.0+**
- Swift **5.9+**
- iOS **15.0+** / macOS **12.0+** (for console demos, `My Mac` as the run destination)
- A Reachu **GraphQL endpoint** and **API token**

---

## Installation

### Add as a Swift Package (local)
1. In Xcode: **File → Add Packages… → Add Local…** and select the folder containing `Package.swift` (the `ReachuSwiftSDK` root).
2. Choose the products you need (e.g. `ReachuCore`, `ReachuDesignSystem`, etc.).

### Add as a Swift Package (remote)
If you host this repo, you can add it by URL in **Add Packages…** and pick the products as above.

> The SDK ships with runnable **console demos** under `Demo/ReachuDemoSdk/…`. These are separate executable targets for fast manual testing.

---

## Architecture

- **Core / GraphQL**
  - `GraphQLHTTPClient`: lightweight HTTP client for GraphQL POST with JSON body.
  - `GraphQLErrorMapper`: maps HTTP & GraphQL errors to typed `SdkException` variants.
  - `GraphQLPick`: small utilities to extract JSON subtrees and decode `Codable` DTOs.

- **Error Model**
  - `SdkException` (+ `AuthException`, `ValidationException`, `RateLimitException`, etc.).
  - All repositories throw these errors for consistent handling.

- **Repositories** (`Sources/ReachuCore/Domain/Repositories`)
  - `CartRepositoryGQL`, `CheckoutRepositoryGQL`, `DiscountRepositoryGQL`,
    `PaymentRepositoryGQL`, `MarketRepositoryGQL`, `Channel*RepositoryGQL`, `ProductRepositoryGQL`.

- **Operations & Models**
  - GraphQL queries/mutations under `Core/Operations/*.swift`.
  - DTOs in `Domain/Models/*.swift` (typed `Codable` models).

- **Modules**
  - High‑level entry points grouping repositories (e.g., `CartModule`, `CheckoutModule`, etc.).
  - `SdkClient` wires the `GraphQLHTTPClient` and exposes module instances.

---

## Quickstart

```swift
import ReachuCore

let apiKey   = "<YOUR_TOKEN>"
let baseURL  = URL(string: "https://your-host/graphql")!
let sdk      = SdkClient(baseUrl: baseURL, apiKey: apiKey)

// Example: get available markets
let markets  = try await sdk.market.getAvailable()

// Example: create cart
let cart     = try await sdk.cart.create(
  customer_session_id: "demo-\(UUID().uuidString)",
  currency: "NOK",
  shippingCountry: "NO"
)
```

> **Auth header**: by default the client sends an `Authorization` header; configure it for `Bearer <token>` or `x-api-key` as your backend requires.

---

## Core Flows

### Cart (create → add item → shipping → checkout)

```swift
// Create cart
let cart = try await sdk.cart.create(
  customer_session_id: "demo-\(UUID().uuidString)",
  currency: "NOK",
  shippingCountry: "NO"
)

// Add item
let line = LineItemInput(productId: 397968, variantId: nil, quantity: 1, priceData: nil)
let afterAdd = try await sdk.cart.addItem(cart_id: cart.cartId, line_items: [line])

// Pick cheapest shipping per supplier and apply to ALL items
let groups = try await sdk.cart.getLineItemsBySupplier(cart_id: afterAdd.cartId)
for group in groups {
  var shippings = group.availableShippings ?? []
  shippings.sort { ($0.price.amount ?? .greatestFiniteMagnitude) < ($1.price.amount ?? .greatestFiniteMagnitude) }
  if let shippingId = shippings.first?.id {
    for item in group.lineItems where item.shipping?.id != shippingId {
      _ = try await sdk.cart.updateItem(cart_id: afterAdd.cartId, cart_item_id: item.id, shipping_id: shippingId, quantity: nil)
    }
  }
}

// Create checkout from cart
let checkout = try await sdk.checkout.create(cart_id: afterAdd.cartId)
```

### Discounts

```swift
// List
let all = try await sdk.discount.get()
let byChannel = try await sdk.discount.getByChannel()

// Add
let iso = ISO8601DateFormatter()
let start = iso.string(from: Date())
let end   = iso.string(from: Calendar.current.date(byAdding: .day, value: 7, to: Date())!)
let add   = try await sdk.discount.add(code: "DEMO-\(UUID().uuidString.prefix(6))",
                                       percentage: 10,
                                       startDate: start, endDate: end, typeId: 2)

// Get by id (Add returns `id`)
let byId  = try await sdk.discount.getById(discountId: add.id)

// Apply & remove
let applied   = try await sdk.discount.apply(code: add.code, cartId: checkout.cartId)
let removed   = try await sdk.discount.deleteApplied(code: add.code, cartId: checkout.cartId)
```

### Checkout (update keys parity)

`CheckoutRepositoryGQL.update` validates non‑empty strings when provided and expects **snake_case** keys inside `shipping_address` / `billing_address` (parity with Flutter). Example:

```swift
let address: [String: Any] = [
  "address1": "Karl Johans gate 1",
  "address2": "Suite 2",
  "city": "Oslo",
  "company": "ACME AS",
  "country": "Norway",
  "country_code": "NO",
  "email": "demo@acme.test",
  "first_name": "Ola",
  "last_name": "Nordmann",
  "phone": "41234567",
  "phone_code": "+47",
  "province": "",
  "province_code": "",
  "zip": "0154"
]

let updated = try await sdk.checkout.update(
  checkout_id: /* id */,
  status: nil,
  email: "demo@acme.test",
  success_url: "https://dev.reachu.io/demo/success",
  cancel_url: "https://dev.reachu.io/demo/cancel",
  payment_method: "Klarna",                 // optional; set if your flow requires it
  shipping_address: address,
  billing_address: address,
  buyer_accepts_terms_conditions: true,
  buyer_accepts_purchase_conditions: true
)
```

### Payments (Stripe / Klarna / Vipps)

```swift
// Available methods
let methods = try await sdk.payment.getAvailableMethods()

// Stripe (client intent + platform builder / hosted link)
let intent  = try await sdk.payment.stripeIntent(checkoutId: updated.id, returnEphemeralKey: true)
let link    = try await sdk.payment.stripeLink(checkoutId: updated.id, successUrl: "https://dev.reachu.io/success",
                                               paymentMethod: "card", email: "demo@acme.test")

// Klarna
let klarna  = try await sdk.payment.klarnaInit(checkoutId: updated.id, countryCode: "NO",
                                               href: "https://dev.reachu.io/success", email: "demo@acme.test")

// Vipps
let vipps   = try await sdk.payment.vippsInit(checkoutId: updated.id, email: "demo@acme.test",
                                              returnUrl: "https://dev.reachu.io/success")
```

### Products (unified query)

All product searches are built on **one unified query** `GET_PRODUCTS_CHANNEL_QUERY` that always returns an **array**.  
Repository helpers convert single‑item calls by taking the **first** element when appropriate.

```swift
// Single product by id (unwrap first)
let p = try await sdk.product.getByParams(currency: "NOK", imageSize: "large",
                                          sku: nil, barcode: nil, productId: 397968,
                                          shippingCountryCode: "NO")

// Multiple by ids
let arr = try await sdk.product.getByIds(productIds: [397968], currency: "NOK",
                                         imageSize: "large", useCache: true,
                                         shippingCountryCode: "NO")

// By category / categories
let byCat   = try await sdk.product.getByCategoryId(categoryId: 123, currency: "NOK",
                                                    imageSize: "large", shippingCountryCode: "NO")
let byCats  = try await sdk.product.getByCategoryIds(categoryIds: [123, 456], currency: "NOK",
                                                     imageSize: "large", shippingCountryCode: "NO")

// By sku / barcode (array)
let bySku   = try await sdk.product.getBySkus(sku: "ABC-123", productId: nil, currency: "NOK",
                                              imageSize: "large", shippingCountryCode: "NO")
let byBc    = try await sdk.product.getByBarcodes(barcode: "EAN-0001", productId: nil, currency: "NOK",
                                                  imageSize: "large", shippingCountryCode: "NO")
```

### Channel Info & Categories

```swift
let channels = try await sdk.channel.info.getChannels()
let purchase = try await sdk.channel.info.getPurchaseConditions()
let terms    = try await sdk.channel.info.getTermsAndConditions()

let categories = try await sdk.channel.category.get()
```

### Markets

```swift
let available = try await sdk.market.getAvailable()
```

---

## Console Demos

Every module ships a runnable console demo with hardcoded values and pretty JSON logs:

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

> In Xcode, open `Package.swift`, pick the demo **scheme** (▸) and run on **My Mac**.

---

## Project Layout

```
Sources/ReachuCore/
  Core/
    Errors/                # SdkException & friends
    GraphQL/               # Client + error mapper + ops bundle
    Helpers/GraphQLPick.swift
    Operations/            # CartGraphQL.swift, CheckoutGraphQL.swift, ...
  Domain/
    Models/                # CartModels.swift, ProductModels.swift, ...
    Repositories/          # *Repository.swift (GQL implementations)
  Modules/
    Channel/               # Channel*, Product*, Info*
    CartModule.swift
    CheckoutModule.swift
    DiscountModule.swift
    MarketModule.swift
    PaymentModule.swift
  Sdk.swift                # SdkClient wiring

Demo/ReachuDemoSdk/
  CartDemo/ …
  DiscountDemo/ …
  MarketDemo/ …
  ChannelDemo/
    InfoDemo/ …
    CategoryDemo/ …
    ProductDemo/ …
  CheckoutDemo/ …
  PaymentDemo/ …
  Sdk/ …
Utils/Logger.swift         # JSON + colored sections
```

---

## Troubleshooting

- **'@main' attribute cannot be used in a module that contains top-level code'**  
  Each demo target must contain exactly one `main.swift`. If you nest sub‑demos (e.g., under `ChannelDemo/…`), add `exclude: ["SubDemoA", …]` in the parent target or set `sources: ["main.swift"]` in each sub‑demo target to compile only that file.

- **Xcode runs `ReachuSwiftSDK-Package` instead of the demo**  
  `Product → Scheme → Edit Scheme… → Build`: keep only the row with the **▸** icon for your demo. Clean the build folder (⇧⌘K) and run again.

- **SPM warning: “Source files for target X should be under Sources/X…”**  
  Ensure each executable target has a proper `path:` pointing to the demo folder and the folder contains a `main.swift`.

- **No auth / 401**  
  Confirm auth header convention: `Authorization: Bearer <token>` or `x-api-key`. Configure your `GraphQLHTTPClient` accordingly.

---

## License

MIT © Reachu
