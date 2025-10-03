# Configuración de Orientaciones para Video Player

Para que el video player funcione correctamente en horizontal (landscape), necesitas habilitar todas las orientaciones en Xcode:

## 📱 Pasos en Xcode:

1. **Abre el proyecto** `tv2demo.xcodeproj`

2. **Selecciona el target** `tv2demo` en el navegador de proyectos

3. **Ve a la pestaña "General"**

4. **En "Deployment Info"**, busca la sección "iPhone Orientation"

5. **Activa TODAS las orientaciones**:
   - ✅ Portrait
   - ✅ Landscape Left
   - ✅ Landscape Right
   - ⬜ Upside Down (opcional)

## ✅ Resultado:

Una vez configurado:
- La app se mantiene en **Portrait** por defecto
- Al abrir el video player, se **habilita Landscape** automáticamente
- Puedes rotar el dispositivo y el video se adaptará
- Al cerrar el player, vuelve a **Portrait only**

## 🎥 Características en Landscape:

- ✅ Controles optimizados para horizontal
- ✅ Títulos más compactos
- ✅ Botones de tamaño ajustado
- ✅ Progress bar completo
- ✅ Experiencia inmersiva fullscreen

## 🔧 Verificación:

Para verificar que funciona:
1. Compila y ejecuta la app
2. Navega a un match
3. Tap en "Spill av"
4. Rota el dispositivo a horizontal
5. Los controles deben adaptarse automáticamente

---

**Nota**: Si no ves las opciones de orientación en Xcode, asegúrate de estar editando el **target** correcto (tv2demo), no el proyecto raíz.

