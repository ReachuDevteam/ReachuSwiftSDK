# 📥 Cómo Descargar y Agregar tu Video de Vimeo

## ✅ Estado Actual

El video ahora está alojado en **Firebase Storage** y funciona perfectamente. Este documento explica las diferentes opciones disponibles.

## ✅ Solución: Descargar y Agregar Video Local

### Paso 1: Descargar el Video de Vimeo

**Opción A - Desde Vimeo (Si eres el dueño):**
1. Ve a: https://vimeo.com/1124046641
2. Click en **Download** (abajo del video)
3. Selecciona la calidad que prefieras (ej: 720p HD)
4. Guarda como `match.mp4`

**Opción B - Usando una herramienta:**
```bash
# Si tienes youtube-dl o yt-dlp instalado:
yt-dlp -o match.mp4 https://vimeo.com/1124046641

# O:
youtube-dl -o match.mp4 https://vimeo.com/1124046641
```

**Opción C - Servicios online:**
- https://vimeodownloader.net/
- https://www.downloadhelper.net/

### Paso 2: Agregar el Video a Xcode

1. **Abre el proyecto** `tv2demo.xcodeproj` en Xcode

2. **Arrastra el archivo** `match.mp4` al Project Navigator
   - Puedes ponerlo en la carpeta `Configuration/`
   - O directamente en la raíz del grupo `tv2demo`

3. **IMPORTANTE - Marca estas opciones:**
   - ✅ **Copy items if needed** (copiar al proyecto)
   - ✅ **Add to targets:** `tv2demo`
   - ✅ **Create groups** (no "Create folder references")

4. **Verifica:**
   - El archivo aparece en Project Navigator con el ícono de video
   - Click en `match.mp4` → Inspector → Target Membership → ✅ tv2demo

### Paso 3: Compilar y Probar

```bash
# Limpia el build
Product → Clean Build Folder (Cmd + Shift + K)

# Compila de nuevo
Product → Run (Cmd + R)
```

**En la consola verás:**
```
🎥 [VideoPlayer] Using local video: match.mp4
▶️ [VideoPlayer] Initializing player...
```

✅ **El video debería reproducirse instantáneamente sin errores**

## 📦 Consideraciones del Tamaño

| Calidad | Tamaño Aproximado (por minuto) |
|---------|----------------------------------|
| 360p | ~3-5 MB/min |
| 480p | ~5-8 MB/min |
| 720p HD | ~10-15 MB/min |
| 1080p Full HD | ~20-30 MB/min |

Tu video dura **51 minutos** (3109 segundos según oEmbed):
- 360p: ~150-250 MB
- 720p: ~500-750 MB
- 1080p: ~1-1.5 GB

### Recomendación:
- **Para demo/testing:** Usa 720p (buen balance calidad/tamaño)
- **Para producción:** Considera usar 480p o 720p máximo

## 🎯 Ventajas del Video Local

✅ **Reproducción instantánea** (sin buffering)
✅ **Funciona offline**
✅ **No depende de Vimeo o internet**
✅ **Sin problemas de CORS/SSL**
✅ **Soporta AirPlay/Casting perfectamente**
✅ **Controles personalizados funcionan 100%**

## 🔄 Hosting Remoto (OPCIÓN ACTUAL EN USO) ✅

El video actualmente está alojado en **Firebase Storage**, que es la opción recomendada:

### Video Actual:
```
Barcelona vs PSG - UCL 01.10.2025 (1080p)
Firebase Storage URL con token persistente
```

### Ventajas de Firebase Storage:
✅ **App ligera** (no aumenta el tamaño del .ipa)
✅ **URLs directos** sin problemas CORS/SSL
✅ **Tokens persistentes** (no expiran automáticamente)
✅ **CDN global rápido** (streaming sin buffering)
✅ **Gratis** hasta 5GB storage + 1GB/día transferencia
✅ **Actualización fácil** (cambias video sin actualizar app)

### Cómo subir videos a Firebase Storage:

1. **Ve a Firebase Console:** https://console.firebase.google.com
2. **Storage → Upload File**
3. **Click derecho en el archivo → Get download URL**
4. **Copia el URL completo** (con `?alt=media&token=...`)
5. **Actualiza el código:**
```swift
let firebaseVideoURL = "TU_URL_DE_FIREBASE"
```

### Otras opciones de hosting:
- **AWS S3 + CloudFront** (profesional, escalable)
- **Cloudflare R2** (más barato que S3)
- **Backblaze B2** (muy económico)
- **Tu propio servidor**

## ❓ Preguntas Frecuentes

**P: ¿El video local aumenta mucho el tamaño de la app?**
R: Sí, pero para una app de TV/streaming es normal. Puedes compensar con:
- Usar calidad 480p/720p en vez de 1080p
- Comprimir el video con HandBrake
- Usar hosting remoto en lugar de bundle

**P: ¿Por qué no funciona Vimeo directamente?**
R: Los URLs de Vimeo CDN tienen protección anti-hotlinking y expiran. Son diseñados para su player web, no para AVPlayer nativo.

**P: ¿Puedo usar YouTube?**
R: No directamente con AVPlayer. Necesitarías WKWebView con el iframe embed de YouTube.

## 🚀 Siguiente Paso

1. Descarga tu video de Vimeo
2. Agrégalo a Xcode como `match.mp4`
3. ✅ Listo, funcionará perfectamente

¿Necesitas ayuda con alguno de estos pasos?

