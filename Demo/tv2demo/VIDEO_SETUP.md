# 🎥 Configuración del Video Player

## Estado Actual

El video player está configurado para cargar videos en este orden de prioridad:

### 1️⃣ Video Local (Recomendado para demo)
Si incluyes un archivo `match.mp4` en el bundle del proyecto, se usará automáticamente.

**Ventajas:**
- ✅ Funciona sin internet
- ✅ No hay límites ni expiraciones
- ✅ Reproducción instantánea

**Cómo agregar:**
1. En Xcode, arrastra tu video `match.mp4` al proyecto
2. Asegúrate de marcar: ✅ "Copy items if needed"
3. Target: ✅ `tv2demo`
4. ✅ Listo, el player lo detectará automáticamente

### 2️⃣ Video de Firebase Storage (ACTUAL - EN USO)
El player carga el video directamente desde Firebase Storage.

**Estado:** ✅ Funcional y recomendado
- URL directo al archivo MP4 en Firebase Storage
- Token persistente (no expira hasta que se revoque manualmente)
- Sin problemas de CORS/SSL
- Funciona perfectamente con AVPlayer
- Requiere conexión a internet

**Video actual:**
```
Barcelona vs PSG - UCL 01.10.2025 (1080p)
https://firebasestorage.googleapis.com/v0/b/tipio-1ec97.appspot.com/o/...
```

**Ventajas de Firebase Storage:**
✅ URLs directos sin restricciones CORS
✅ Tokens persistentes (no expiran automáticamente)
✅ Compatible 100% con AVPlayer
✅ Soporte completo de AirPlay/Casting
✅ Sin buffering (CDN global rápido)
✅ Gratis hasta 5GB de almacenamiento y 1GB/día de transferencia

### 3️⃣ Fallback Video
Si Vimeo falla, usa un video de prueba de Apple (HLS stream).

## 🔧 Solución para el Error Actual

Los errores que viste:
```
nw_socket_set_connection_idle [C5.1.1.1:3] setsockopt SO_CONNECTION_IDLE failed
CFHTTP signalled err=-12660
FigStreamPlayer signalled err=-12783
```

Indican que el URL de Vimeo expiró o tiene problemas de SSL/CORS.

### ✅ Solución Inmediata:

**Opción A: Agregar video local** (RECOMENDADO)
1. Descarga tu video de Vimeo como MP4
2. Renómbralo a `match.mp4`
3. Arrástralo a Xcode → carpeta `tv2demo`
4. ✅ Funcionará instantáneamente

**Opción B: Esperar al fallback**
- El player automáticamente usará un video de prueba de Apple si Vimeo falla
- Es un HLS stream que siempre funciona

**Opción C: Mejorar el servicio de Vimeo**
```swift
// Ya implementado en VimeoService.swift
// - Busca URLs MP4 progresivos (mejor compatibilidad)
// - Extrae URLs HLS frescos
// - Maneja mejor los errores SSL/CORS
```

## 📱 Para el Build en tu Teléfono

### Si usas video local:
1. Agrega `match.mp4` al proyecto en Xcode
2. Build → La app será un poco más pesada (tamaño del video)
3. ✅ Funciona offline

### Si usas Vimeo (sin video local):
1. Build → App ligera (~10-20 MB)
2. Requiere internet para reproducir
3. El video se carga de Vimeo dinámicamente

## 🔍 Debugging

Los logs del player te dirán qué está pasando:

```swift
🎥 [VideoPlayer] Using local video: match.mp4
// → Video local encontrado y usado

🌐 [VideoPlayer] Attempting to load Vimeo video...
🔍 [VimeoService] Fetching stream URL for video: 1124046641
📡 [VimeoService] Response status: 200
✅ [VimeoService] Found MP4 URL
✅ [VideoPlayer] Vimeo stream ready!
// → Vimeo funcionó correctamente

❌ [VideoPlayer] Vimeo failed: streamURLNotFound
⚠️ [VideoPlayer] Using fallback test video
// → Vimeo falló, usando video de prueba
```

## 🎯 Recomendación

Para la mejor experiencia y para evitar problemas:

1. **Descarga tu video de Vimeo** (Settings → Download)
2. **Agrégalo como `match.mp4`** al proyecto
3. ✅ **Siempre funcionará**, sin depender de internet o Vimeo

El servicio de Vimeo está ahí como backup/alternativa, pero un video local es más confiable para demos.

