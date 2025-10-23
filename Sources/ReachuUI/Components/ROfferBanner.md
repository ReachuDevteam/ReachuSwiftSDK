# ROfferBanner Component

Dynamic offer banner component that receives configuration from backend via WebSocket.

## Features

- ✅ Dynamic logo from URL
- ✅ Configurable title and subtitle
- ✅ Background image with overlay
- ✅ Real-time countdown timer
- ✅ Discount badge
- ✅ Call-to-action button
- ✅ WebSocket integration for live updates

## Usage

### Basic Usage

```swift
import ReachuUI
import ReachuCore

struct ContentView: View {
    var body: some View {
        VStack {
            // Simple container that handles everything
            ROfferBannerContainer(campaignId: 10)
            
            // Rest of your content...
        }
    }
}
```

### Advanced Usage with Custom Management

```swift
struct ContentView: View {
    @StateObject private var componentManager = ComponentManager(campaignId: 10)
    
    var body: some View {
        VStack {
            if let bannerConfig = componentManager.activeBanner {
                ROfferBanner(config: bannerConfig)
            }
            
            // Rest of your content...
        }
        .onAppear {
            Task {
                await componentManager.connect()
            }
        }
        .onDisappear {
            componentManager.disconnect()
        }
    }
}
```

## Backend Integration

### WebSocket Messages

The component listens for these WebSocket messages:

#### Component Status Changed
```json
{
  "type": "component_status_changed",
  "data": {
    "componentId": "abc123-xyz789",
    "status": "active",
    "config": {
      "logoUrl": "https://storage.url/xxl-logo.png",
      "title": "Ukens tilbud",
      "subtitle": "Se denne ukes beste tilbud",
      "backgroundImageUrl": "https://storage.url/football-grass.jpg",
      "countdownEndDate": "2025-10-30T23:59:59Z",
      "discountBadgeText": "Opp til 30%",
      "ctaText": "Se alle tilbud →",
      "ctaLink": "https://xxlsports.no/offers",
      "overlayOpacity": 0.4
    }
  }
}
```

#### Campaign Ended
```json
{
  "type": "campaign_ended"
}
```

### API Endpoints

#### Get Active Components
```
GET /api/campaigns/{campaignId}/active-components
```

Response:
```json
[
  {
    "id": "abc123",
    "type": "offer_banner",
    "config": { /* banner configuration */ }
  }
]
```

#### WebSocket Connection
```
wss://your-server.com/ws/{campaignId}
```

## Configuration

### OfferBannerConfig Properties

| Property | Type | Description |
|----------|------|-------------|
| `logoUrl` | String | URL for the logo image |
| `title` | String | Main banner title |
| `subtitle` | String? | Optional subtitle |
| `backgroundImageUrl` | String | Background image URL |
| `countdownEndDate` | String | ISO 8601 timestamp for countdown end |
| `discountBadgeText` | String | Text for discount badge |
| `ctaText` | String | Call-to-action button text |
| `ctaLink` | String? | Optional CTA button link |
| `overlayOpacity` | Double? | Background overlay opacity (0.0-1.0) |

## Lifecycle

1. **App Launch**: Fetches active components from API
2. **WebSocket Connection**: Connects for real-time updates
3. **Component Updates**: Shows/hides banner based on WebSocket messages
4. **Campaign End**: Automatically hides all components

## Error Handling

- Invalid URLs fallback to placeholder images
- Invalid countdown dates are logged and ignored
- WebSocket connection failures are handled gracefully
- API failures don't prevent app functionality

## Styling

The component uses a fixed height of 180 points and includes:
- Rounded corners (12pt radius)
- 20pt padding
- Purple CTA button
- Semi-transparent overlay
- White text with proper contrast

## Dependencies

- SwiftUI
- Foundation
- URLSession (for API calls)
- WebSocket (for real-time updates)
