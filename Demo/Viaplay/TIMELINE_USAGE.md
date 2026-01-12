# 🎬 Cómo Usar el Timeline Sincronizado

## 🎯 Estado Actual

### ✅ Implementado:
- Timeline unificado con todos los eventos sincronizados
- 24 tipos de eventos soportados
- Navegación por scrubber
- Filtrado automático de eventos por tiempo

### ⚠️ Para Probar:

**Navegar en el Timeline**:
1. Abre "Interaktiv Demo" desde Sport → Barcelona-PSG
2. Arrastra el scrubber en la barra de timeline
3. Observa cómo los eventos aparecen/desaparecen

**Ejemplo**:
```
Timeline en 0' (inicio):
├─ ⚽ Avspark announcement
├─ 📢 Admin: "Velkommen til Champions League!"
└─ 💬 Chat: "Endelig! La oss gå!" (0'45")

Arrastra a minuto 13:
├─ Todo lo anterior +
├─ 🐦 Tweet: Luka Modrić (2')
├─ 🔄 Bytte (5')
├─ 🐦 Tweet: Haaland (8')
├─ 📊 Poll: "Hvem vinner?" (10')
├─ 📢 Admin: "Barcelona kontrollerer..." (10')
├─ ⚽ MÅL: A. Diallo (13')
└─ 💬 Chat: "GOOOOOL!!!" (13'05")

Arrastra a minuto 32:
├─ Todo lo anterior +
├─ 🐦 Tweet: Mbappé (13'30")
├─ 🟨 Yellow Card (18', 25')
├─ 💬 Más chats hasta minuto 32
└─ ⚽ MÅL: B. Mbeumo (32')

Retrocede a minuto 5:
├─ ⚽ Avspark
├─ 📢 Admin welcome
├─ 💬 Chats hasta 5'
└─ 🔄 Bytte (5')
❌ NO aparece: Goles, tweets posteriores, polls
```

## 🔊 Audio/Video

**Nota**: LiveMatchView simula que el video está en la TV, no hay video visible en el móvil.

El botón de mute está conectado pero:
- `VideoPlayerViewModel` no carga video en LiveMatchView
- Solo es funcional en `ViaplayVideoPlayer` (video player completo)
- En LiveMatchView solo cambia el estado visual

### Para Audio Funcional:

Necesitarías conectar a un audio stream real:
```swift
// En LiveMatchViewModel
let audioPlayer = AVPlayer(url: audioStreamURL)
func toggleMute() {
    audioPlayer.isMuted.toggle()
}
```

## 📊 Timeline Data Actual

### Eventos Pre-Generados (Barcelona - PSG):

**Minuto 0**:
- 0s - Avspark announcement
- 10s - Admin welcome comment
- 45s - Chat inicial

**Minuto 2-10**:
- 90s - Chat
- 120s - Tweet Luka Modrić "Nikada ne odustaj!"
- 300s - Substitution
- 330s - Chat sobre el cambio
- 480s - Tweet Haaland
- 600s - Admin comment táctico
- 600s - Poll "Hvem vinner?"

**Minuto 13** (GOL):
- 780s - MÅL A. Diallo (1-0)
- 785s - Chat "GOOOOOL!!!"
- 787s - Chat "Hvilken pasning!"
- 790s - Chat "Utrolig avslutning!"
- 795s - Admin "Nydelig mål!" (pinned)
- 810s - Tweet Mbappé

**Minuto 18-32**:
- 900s - Stats update + Chat
- 1080s - Yellow Card Casemiro
- 1200s - Chat + Product
- 1500s - Yellow Card Tavernier
- 1800s - Poll "Hvem er best?" + Stats
- 1920s - MÅL B. Mbeumo (2-0)
- 1930s - Chat "ENDA ET MÅL!"
- 1935s - Admin "Mbeumo dobler!" + Chat

**Minuto 45**:
- 2700s - Half Time announcement

## 🎯 Testing Checklist

Para verificar que el timeline funciona:

- [ ] Arrastra scrubber a minuto 0 → Solo ves Avspark + Admin welcome
- [ ] Arrastra a minuto 2 → Aparece tweet de Luka Modrić
- [ ] Arrastra a minuto 13 → Aparece gol + chats de celebración
- [ ] Arrastra a minuto 32 → Aparece segundo gol
- [ ] Retrocede a minuto 5 → Desaparecen goles y eventos futuros
- [ ] Vuelve a LIVE → Auto-avanza mostrando eventos

## 🔧 Próximos Pasos

### Inmediato:
1. Probar navegación del timeline
2. Verificar que eventos aparecen/desaparecen correctamente
3. Confirmar que todo está sincronizado

### Backend Integration:
1. Conectar a API real para cargar eventos
2. WebSocket para eventos en tiempo real
3. Audio stream real si es necesario

---

**Para probar AHORA**: 
1. Compila la app
2. Sport → Barcelona-PSG → "Interaktiv Demo"
3. Arrastra el scrubber y observa los eventos
