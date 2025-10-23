# Reachu UI Components

This directory contains pre-built SwiftUI components for Reachu functionality.

## Available Components

### ROfferBanner

Dynamic offer banner component that receives configuration from backend via WebSocket.

**Features:**
- ✅ Dynamic logo from URL
- ✅ Configurable title and subtitle  
- ✅ Background image with overlay
- ✅ Real-time countdown timer
- ✅ Discount badge
- ✅ Call-to-action button
- ✅ WebSocket integration for live updates

**Usage:**
```swift
import ReachuUI

// Simple usage with automatic lifecycle management
ROfferBannerContainer(campaignId: 10)

// Advanced usage with custom management
@StateObject private var componentManager = ComponentManager(campaignId: 10)

if let bannerConfig = componentManager.activeBanner {
    ROfferBanner(config: bannerConfig)
}
```

**Backend Integration:**
- WebSocket connection: `wss://your-server.com/ws/{campaignId}`
- API endpoint: `GET /api/campaigns/{campaignId}/active-components`
- Real-time updates via WebSocket messages

### RProductCard

Product card component for displaying products in grids or lists.

### RProductSlider

Horizontal scrolling product slider component.

### RCheckoutOverlay

Full-screen checkout overlay with cart management.

### RProductDetailOverlay

Product detail modal with full-screen presentation.

### RFloatingCartIndicator

Persistent floating cart indicator with badge.

## Integration Guide

### 1. Add to Your Project

```swift
import ReachuUI
import ReachuCore
```

### 2. Configure Backend Connection

```swift
@StateObject private var componentManager = ComponentManager(campaignId: yourCampaignId)

// Connect on app launch
.onAppear {
    Task {
        await componentManager.connect()
    }
}
```

### 3. Use Components

```swift
VStack {
    // Dynamic offer banner
    if let bannerConfig = componentManager.activeBanner {
        ROfferBanner(config: bannerConfig)
    }
    
    // Your app content
    HomeView()
}
```

## Backend Requirements

### WebSocket Messages

The components expect these WebSocket message types:

- `component_status_changed`: Show/hide components
- `campaign_ended`: Hide all components

### API Endpoints

- `GET /api/campaigns/{campaignId}/active-components`: Get initial state
- `wss://your-server.com/ws/{campaignId}`: Real-time updates

## Configuration

Components are configured via JSON messages from your backend. See individual component documentation for specific configuration options.

## Error Handling

- Invalid URLs fallback to placeholder content
- WebSocket connection failures are handled gracefully
- API failures don't prevent app functionality
- Components gracefully handle missing configuration

## Styling

Components use Reachu's design system with:
- Consistent spacing and typography
- Adaptive colors for light/dark mode
- Accessibility support
- Responsive layouts
