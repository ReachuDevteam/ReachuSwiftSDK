# 📁 Configuration Files

## 🎯 **Para Desarrolladores:**

Estos archivos de configuración deben ser **copiados a tu proyecto** para personalizar el SDK.

### **📋 Archivos Disponibles:**

| Archivo | Descripción | Uso |
|---------|-------------|-----|
| `reachu-config-example.json` | **Configuración principal** (Dark Streaming Theme) | Copia como `reachu-config.json` |
| `reachu-config-dark-streaming.json` | **Tema oscuro** para streaming | Para apps de streaming |
| `reachu-config-automatic.json` | **Tema automático** (iOS standard) | Para apps generales |
| `reachu-config-starter.json` | **Configuración mínima** | Para empezar rápido |

### **🚀 Setup Rápido:**

```bash
# 1. Copia el archivo que prefieras a tu proyecto
cp reachu-config-example.json reachu-config.json

# 2. En tu app, carga la configuración
try ConfigurationLoader.loadConfiguration()
```

### **⚡ Cambio Rápido de Temas:**

```swift
// En tu AppDelegate o main
try ConfigurationLoader.loadFromJSON(fileName: "reachu-config-dark-streaming")
// O
try ConfigurationLoader.loadFromJSON(fileName: "reachu-config-automatic")
```

### **🔧 Environment Variables (Xcode):**

1. **Edit Scheme** → **Run** → **Environment Variables**
2. **Add**: `REACHU_CONFIG_TYPE` = `dark-streaming`
3. **Run** → Usa automáticamente el tema correcto

---

## 📖 **Documentación Completa:**

- **`CONFIG_SWITCHING_GUIDE.md`** - Guía completa de switching
- **`README.md`** (raíz del SDK) - Documentación general

---

## 🎨 **Comparación Visual:**

### **🌙 Dark Streaming:**
- Background: **#000000** (negro puro)
- Surface: **#0D0D0F** (casi negro)
- Primary: **#0066FF** (azul vibrante)
- **Ideal para**: Apps de streaming, gaming, media

### **🌞 Automatic:**
- Background: **Sistema** (Light/Dark adaptive)
- Surface: **#1C1C1E** (dark) / **#FFFFFF** (light)
- Primary: **#0A84FF** (iOS standard)
- **Ideal para**: Apps generales, ecommerce

**¡Elige el que mejor se adapte a tu app!** 🎯
