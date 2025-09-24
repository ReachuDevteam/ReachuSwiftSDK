# 🚀 Environment Variables Setup Guide

## ⚡ **3 Formas de Configurar Environment Variables en TU APP:**

### **🥇 MÉTODO 1: .xcconfig Files (Más Profesional)**

1. **En TU APP**: Project Settings → Info → Configurations
2. **Duplicar** Debug configuration → "Debug-Dark"
3. **Asignar** `DarkStreaming.xcconfig` a "Debug-Dark"
4. **Duplicar** Debug configuration → "Debug-Auto" 
5. **Asignar** `AutomaticTheme.xcconfig` a "Debug-Auto"
6. **Cambiar** entre configuraciones para cambiar temas

### **🥈 MÉTODO 2: Manual Environment Variables (Más Rápido)**

1. **En TU APP**: Edit Scheme → **Run** → **Environment Variables**
2. **Add**: `REACHU_CONFIG_TYPE` = `dark-streaming`
3. **Change to**: `REACHU_CONFIG_TYPE` = `automatic`
4. **Run** → El SDK automáticamente usa el tema correcto

### **🥉 MÉTODO 3: Código (Más Control)**

```swift
// En TU APP (AppDelegate o App.swift)
try ConfigurationLoader.loadFromJSON(fileName: "reachu-config-dark-streaming")
// O
try ConfigurationLoader.loadFromJSON(fileName: "reachu-config-automatic")
```

---

## 📁 **Archivos Creados:**

| Archivo | Propósito |
|---------|-----------|
| `EnvironmentVariables.xcconfig` | **Configuración principal** con todas las opciones |
| `DarkStreaming.xcconfig` | **Tema oscuro** para streaming |
| `AutomaticTheme.xcconfig` | **Tema automático** iOS |
| `ENVIRONMENT_SETUP.md` | **Esta guía** |

---

## 🎯 **Configuraciones Disponibles:**

### **🌙 Dark Streaming:**
```bash
REACHU_CONFIG_TYPE = dark-streaming
```
- Background: **#000000** (negro puro)
- Surface: **#0D0D0F** (casi negro)
- Primary: **#0066FF** (azul vibrante)
- **Ideal para**: Apps de streaming, gaming, media

### **🌞 Automatic:**
```bash
REACHU_CONFIG_TYPE = automatic
```
- Background: **Sistema** (Light/Dark adaptive)
- Surface: **#1C1C1E** (dark) / **#FFFFFF** (light)
- Primary: **#0A84FF** (iOS standard)
- **Ideal para**: Apps generales, ecommerce

---

## 🔍 **Verificar que Funciona:**

En la consola de Xcode deberías ver:
```
🔧 [Config] Using environment config type: dark-streaming
📄 [Config] Loading configuration from: reachu-config-dark-streaming.json
✅ [Config] Configuration loaded successfully: Dark Streaming Theme
✅ Reachu SDK configuration loaded successfully
```

---

## 🛠️ **Para Desarrolladores:**

1. **Copia** estos archivos a tu proyecto
2. **Configura** según tu preferencia
3. **Usa** `ConfigurationLoader.loadConfiguration()` en tu app

**¡Ahora puedes cambiar temas súper rápido!** ⚡🎨
