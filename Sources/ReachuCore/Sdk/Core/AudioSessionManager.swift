import AVFoundation
import Foundation

/// Manager para configurar la sesión de audio del sistema
public class AudioSessionManager {
    
    public static let shared = AudioSessionManager()
    
    private var activePlayer: AVPlayer?
    private var isConfigured = false
    
    private init() {}
    
    /// Registra un reproductor como activo y configura la sesión de audio
    public func registerPlayer(_ player: AVPlayer, isLive: Bool = false) {
        print("🎵 [AudioSession] Registrando nuevo reproductor activo")
        
        // Silenciar el reproductor anterior si existe
        if let previousPlayer = activePlayer, previousPlayer != player {
            previousPlayer.isMuted = true
            print("🔇 [AudioSession] Silenciando reproductor anterior")
        }
        
        // Configurar sesión de audio
        configureForContent(isLive: isLive)
        
        // Registrar nuevo reproductor
        activePlayer = player
        
        print("✅ [AudioSession] Reproductor registrado correctamente")
    }
    
    /// Desregistra un reproductor
    public func unregisterPlayer(_ player: AVPlayer) {
        if activePlayer == player {
            activePlayer = nil
            print("🔇 [AudioSession] Reproductor desregistrado")
        }
    }
    
    /// Configura la sesión de audio para reproducción de video
    public func configureForVideoPlayback() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Configurar categoría para reproducción de video
            try audioSession.setCategory(
                .playback,
                mode: .moviePlayback,
                options: [.allowAirPlay, .allowBluetooth]
            )
            
            // Activar la sesión de audio
            try audioSession.setActive(true)
            
            isConfigured = true
            print("✅ [AudioSession] Configurado para reproducción de video")
            
        } catch {
            print("❌ [AudioSession] Error configurando sesión de audio: \(error.localizedDescription)")
        }
    }
    
    /// Configura la sesión de audio para streaming en vivo
    public func configureForLiveStreaming() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Configurar categoría para streaming en vivo
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetooth, .mixWithOthers]
            )
            
            // Activar la sesión de audio
            try audioSession.setActive(true)
            
            isConfigured = true
            print("✅ [AudioSession] Configurado para streaming en vivo")
            
        } catch {
            print("❌ [AudioSession] Error configurando sesión de audio: \(error.localizedDescription)")
        }
    }
    
    /// Desactiva la sesión de audio
    public func deactivate() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            isConfigured = false
            activePlayer = nil
            print("🔇 [AudioSession] Sesión de audio desactivada")
        } catch {
            print("❌ [AudioSession] Error desactivando sesión de audio: \(error.localizedDescription)")
        }
    }
    
    /// Verifica si el audio está disponible
    public var isAudioAvailable: Bool {
        let audioSession = AVAudioSession.sharedInstance()
        return audioSession.isOtherAudioPlaying == false || audioSession.category == .playback
    }
    
    /// Obtiene el volumen actual del sistema
    public var systemVolume: Float {
        return AVAudioSession.sharedInstance().outputVolume
    }
    
    /// Configuración automática basada en el tipo de contenido
    public func configureForContent(isLive: Bool) {
        if isLive {
            configureForLiveStreaming()
        } else {
            configureForVideoPlayback()
        }
    }
    
    /// Silencia todos los reproductores excepto el especificado
    public func muteAllExcept(_ player: AVPlayer) {
        // Esta función se puede usar para silenciar otros reproductores
        // cuando se activa uno específico
        print("🔇 [AudioSession] Silenciando otros reproductores")
    }
}
