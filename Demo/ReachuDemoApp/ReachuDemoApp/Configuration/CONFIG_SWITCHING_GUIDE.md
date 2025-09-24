# Configuration Switching Guide

## 🔄 **3 Formas de Cambiar Configuraciones:**

### **⚡ MÉTODO 1: Environment Variable (Más Rápido)**

```bash
# En Xcode Scheme > Edit Scheme > Run > Environment Variables
REACHU_CONFIG_TYPE = "dark-streaming"
# O
REACHU_CONFIG_TYPE = "automatic"
```

```swift
// En tu app simplemente usa:
try ConfigurationLoader.loadConfiguration()
// Automáticamente usa la config según environment variable
```

---

### **📁 MÉTODO 2: Archivo Específico**

```swift
// Cargar config específica
try ConfigurationLoader.loadFromJSON(fileName: "reachu-config-dark-streaming")
try ConfigurationLoader.loadFromJSON(fileName: "reachu-config-automatic")
```

---

### **🎯 MÉTODO 3: Copy & Replace (Tradicional)**

```bash
# Para usar Dark Streaming:
cp reachu-config-dark-streaming.json reachu-config.json

# Para usar Automatic:
cp reachu-config-automatic.json reachu-config.json
```

---

## 📁 **Archivos Disponibles:**

### **🌙 Dark Streaming Theme:**
- **File**: `reachu-config-dark-streaming.json`
- **Mode**: `"dark"` (forzado)
- **Background**: `#000000` (negro puro)
- **Surface**: `#0D0D0F` (casi negro)
- **Primary**: `#0066FF` (azul vibrante)
- **LiveShow**: Sin viewer count, UI minimalista

### **🌞 Automatic Theme:**
- **File**: `reachu-config-automatic.json`
- **Mode**: `"automatic"` (sigue sistema)
- **Colors**: Standard iOS
- **LiveShow**: UI completa con controles

### **📝 Main Example:**
- **File**: `reachu-config-example.json`
- **Current**: Dark Streaming Theme
- **Purpose**: Template principal

---

## 🛠️ **Configuración en Xcode:**

### **Para Development:**
1. **Edit Scheme** → **Run** → **Environment Variables**
2. **Add**: `REACHU_CONFIG_TYPE` = `dark-streaming`
3. **Run app** → Usa automáticamente el dark theme

### **Para Testing:**
1. **Change** `REACHU_CONFIG_TYPE` = `automatic`
2. **Run app** → Usa automáticamente el automatic theme

### **Para Production:**
1. **Copy** tu config preferida a `reachu-config.json`
2. **Include** en tu app bundle

---

## 🔍 **Verificar qué Config se está Usando:**

El loader imprime logs:
```
🔧 [Config] Using environment config type: dark-streaming
📄 [Config] Loading configuration from: reachu-config-dark-streaming.json
✅ [Config] Configuration loaded successfully: Dark Streaming Theme
```

## 🎨 **Visual Comparison:**

### **Dark Streaming:**
- Background: **Pure Black** (#000000)
- Cards: **Almost Black** (#0D0D0F)
- Text: **High Contrast** (#FFFFFF)
- Accent: **Vibrant Blue** (#0066FF)

### **Automatic:**
- Background: **System** (Light/Dark adaptive)
- Cards: **Standard** (#1C1C1E in dark)
- Text: **Standard** contrast
- Accent: **Standard Blue** (#0A84FF)

**¿Te gusta este sistema de switching? ¿Prefieres environment variables o copy/paste?**
