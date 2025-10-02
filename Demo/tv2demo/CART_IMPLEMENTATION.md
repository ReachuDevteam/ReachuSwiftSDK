# 🛒 Cart System Implementation Guide

## Overview

This document explains how the shopping cart system is implemented in tv2demo using Reachu SDK components.

## Architecture

```
tv2demoApp (Root)
├── CartManager (@StateObject)           → Global cart state
├── CheckoutDraft (@StateObject)         → Checkout data & validation
└── ContentView
    └── HomeView
        ├── RFloatingCartIndicator       → Floating cart badge
        ├── CartSheetView (sheet)        → Cart items list
        └── RCheckoutOverlay (sheet)     → Complete checkout flow
```

## Components Explained

### 1. **CartManager** (Global State)

**Location:** Initialized in `tv2demoApp.swift`

**Purpose:** 
- Manages all cart operations (add, remove, update)
- Tracks cart items and total
- Controls checkout overlay presentation
- Syncs with Reachu backend

**Key Properties:**
```swift
@Published var items: [CartItem] = []
@Published var isCheckoutPresented = false
@Published var cartTotal: Double = 0.0
var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }
```

**Why @StateObject?**
- Initialized once at app level
- Persists across entire app lifecycle
- Shared via `.environmentObject()` to all child views

### 2. **CheckoutDraft** (Address Management)

**Location:** Initialized in `tv2demoApp.swift`

**Purpose:**
- Stores user shipping/billing information
- Normalizes geographic data (countries, provinces)
- Generates API-ready payloads

**Key Features:**
- Converts "Estados Unidos" → "US" (ISO-2)
- Handles province codes (California → CA)
- Phone code resolution by country

### 3. **RFloatingCartIndicator** (SDK Component)

**Location:** `HomeView.swift` (ZStack overlay)

**Purpose:**
- Shows cart item count
- Displays total price
- Provides quick access to cart
- Auto-hides when cart is empty

**Configuration:**
```swift
RFloatingCartIndicator(
    position: .bottomRight,    // Placement on screen
    size: .medium,            // small/medium/large
    mode: .full              // full/compact/minimal
) {
    showCartSheet = true     // Action on tap
}
```

**Why conditional rendering?**
```swift
if cartManager.itemCount > 0 {
    RFloatingCartIndicator(...)
}
```
Only shows when there are items, saves resources.

### 4. **CartSheetView** (Custom View)

**Location:** `Views/CartSheetView.swift`

**Purpose:**
- Display all cart items
- Allow quantity adjustments
- Show pricing breakdown
- Navigate to checkout

**Structure:**
```swift
CartSheetView
├── Empty State (when no items)
└── Cart Content
    ├── ScrollView (item list)
    │   └── CartItemRow (each product)
    └── Cart Summary
        ├── Subtotal
        ├── Item count
        ├── Total
        └── Checkout button
```

**Why custom instead of SDK component?**
- Matches TV2 brand styling
- Custom layout and animations
- Still uses CartManager internally

### 5. **RCheckoutOverlay** (SDK Component)

**Location:** Sheet presented from `HomeView.swift`

**Purpose:**
- Complete checkout flow
- Multi-step process (Address → Shipping → Payment)
- Stripe/Klarna integration
- Order confirmation

**Flow:**
```
1. Address Entry
   ↓
2. Shipping Options
   ↓
3. Order Summary
   ↓
4. Payment (Stripe/Klarna)
   ↓
5. Success/Confirmation
```

## Data Flow

### Adding a Product

```
User taps "Add to Cart"
        ↓
cartManager.addProduct(product)
        ↓
Updates @Published items
        ↓
UI reacts automatically:
├── FloatingCartIndicator updates count
├── CartSheetView shows new item
└── Total recalculates
```

### Checkout Flow

```
User taps cart indicator
        ↓
showCartSheet = true
        ↓
CartSheetView appears
        ↓
User reviews items
        ↓
Taps "Proceed to Checkout"
        ↓
dismiss() (closes cart sheet)
        ↓
cartManager.showCheckout()
        ↓
isCheckoutPresented = true
        ↓
RCheckoutOverlay appears
        ↓
User completes checkout
        ↓
Cart clears automatically
```

## Environment Object Chain

```
tv2demoApp
├── Creates: CartManager & CheckoutDraft
└── Injects via: .environmentObject()
    ↓
ContentView (has access)
    ↓
HomeView (has access)
    ├── @EnvironmentObject var cartManager
    └── @EnvironmentObject var checkoutDraft
        ↓
    CartSheetView (receives via sheet)
    └── RCheckoutOverlay (receives via sheet)
```

**Key Point:** Any view can access these objects without passing as parameters!

## Sheet Management

### Why Two Separate Sheets?

**Sheet 1: Cart Review** (`showCartSheet`)
- User-controlled
- Can be dismissed freely
- Lightweight

**Sheet 2: Checkout Flow** (`cartManager.isCheckoutPresented`)
- Process-controlled
- Should complete or cancel properly
- Heavier (payment processing)

### Preventing Sheet Conflicts

```swift
// Cart sheet closes
dismiss()

// Then checkout sheet opens
cartManager.showCheckout()
```

SwiftUI handles transition automatically.

## Styling Integration

### TV2 Theme Usage

All custom components use TV2 theme tokens:

```swift
.font(TV2Theme.Typography.headline)
.foregroundColor(TV2Theme.Colors.textPrimary)
.padding(TV2Theme.Spacing.md)
.cornerRadius(TV2Theme.CornerRadius.medium)
```

### SDK Components

SDK components automatically adapt to Reachu configuration:

```swift
// In reachu-config.json
"theme": {
  "darkColors": {
    "primary": "#7B5FFF",      // TV2 purple
    "secondary": "#E893CF"     // TV2 pink
  }
}
```

SDK components use these colors automatically.

## Performance Considerations

### 1. Conditional Rendering
```swift
if cartManager.itemCount > 0 {
    RFloatingCartIndicator(...)
}
```
Indicator only rendered when needed.

### 2. Reactive Updates
```swift
@Published var items: [CartItem]
```
UI updates automatically, no manual refresh.

### 3. Lazy Loading
```swift
ScrollView {
    VStack { ... }  // Not lazy yet, could optimize
}
```
Could use `LazyVStack` for many items.

## Future Enhancements

### 1. Persistence
```swift
// Save cart to UserDefaults or Keychain
func saveCart() {
    let data = try? JSONEncoder().encode(items)
    UserDefaults.standard.set(data, forKey: "cart")
}
```

### 2. Cart Animations
```swift
.animation(.spring(), value: cartManager.items.count)
```

### 3. Product Images
```swift
// Use AsyncImage for real product images
AsyncImage(url: URL(string: item.imageUrl))
```

### 4. Quantity Limits
```swift
func addProduct(_ product: Product) {
    guard currentQuantity < maxQuantity else {
        showError("Maximum quantity reached")
        return
    }
    // Add product
}
```

## Testing the Implementation

### 1. Empty State
- Open app → No cart indicator visible ✓
- Tap nothing → No cart icon ✓

### 2. Adding Items
- Add product → Indicator appears ✓
- Count updates → Badge shows "1" ✓
- Add more → Count increments ✓

### 3. Cart Sheet
- Tap indicator → Sheet opens ✓
- See items → Products listed ✓
- Adjust quantity → Updates immediately ✓
- Remove item → Item disappears ✓

### 4. Checkout Flow
- Tap "Proceed to Checkout" → Sheet closes, checkout opens ✓
- Fill address → CheckoutDraft stores data ✓
- Complete payment → Cart clears ✓

## Troubleshooting

### Cart indicator not showing
**Problem:** Added items but no indicator appears

**Solution:**
```swift
// Check if CartManager is injected
.environmentObject(cartManager)

// Verify condition
if cartManager.itemCount > 0 {  // Should be true
    RFloatingCartIndicator(...)
}
```

### Sheet not opening
**Problem:** Tap indicator but nothing happens

**Solution:**
```swift
// Verify @State is defined
@State private var showCartSheet = false

// Check action is set
RFloatingCartIndicator(...) {
    showCartSheet = true  // This should execute
}

// Verify sheet modifier exists
.sheet(isPresented: $showCartSheet) {
    CartSheetView()
}
```

### Environment object not found
**Problem:** `"No ObservableObject of type CartManager found"`

**Solution:**
```swift
// In tv2demoApp:
ContentView()
    .environmentObject(cartManager)  // Must inject here

// In child view:
@EnvironmentObject private var cartManager: CartManager  // Not optional
```

## Summary

**What we built:**
1. ✅ Global cart state management
2. ✅ Floating cart indicator (SDK component)
3. ✅ Custom cart sheet (TV2 styled)
4. ✅ Full checkout integration (SDK component)
5. ✅ Seamless flow between all components

**Key Principles:**
- **Single source of truth**: CartManager
- **Reactive UI**: @Published properties
- **Environment injection**: Shared state
- **Modular design**: SDK + Custom components
- **Brand consistency**: TV2 theme throughout

**Next Steps:**
1. Add real products to cart
2. Test complete purchase flow
3. Add persistence
4. Implement animations
5. Add error handling


