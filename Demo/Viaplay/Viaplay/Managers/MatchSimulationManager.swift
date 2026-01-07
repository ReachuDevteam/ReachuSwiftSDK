//
//  MatchSimulationManager.swift
//  Viaplay
//
//  Manager para simular eventos del partido en tiempo real
//

import Foundation
import Combine

@MainActor
class MatchSimulationManager: ObservableObject {
    @Published var currentMinute: Int = 0
    @Published var homeScore: Int = 0
    @Published var awayScore: Int = 0
    @Published var events: [MatchEvent] = []
    @Published var isPlaying: Bool = false
    
    private var timer: Timer?
    private var eventTimer: Timer?
    private let matchDuration: Int = 90
    
    // Eventos predefinidos para simular
    private let simulatedEvents: [(minute: Int, event: () -> MatchEvent)] = [
        (0, { MatchEvent(minute: 0, type: .kickOff, player: nil, team: .home, description: nil, score: "0-0") }),
        (5, { MatchEvent(minute: 5, type: .substitution(on: "A. Scott", off: "T. Adams"), player: "A. Scott", team: .away, description: nil, score: nil) }),
        (13, { MatchEvent(minute: 13, type: .goal, player: "A. Diallo", team: .home, description: nil, score: "1-0") }),
        (18, { MatchEvent(minute: 18, type: .yellowCard, player: "Casemiro", team: .home, description: nil, score: nil) }),
        (25, { MatchEvent(minute: 25, type: .yellowCard, player: "M. Tavernier", team: .away, description: nil, score: nil) }),
        (32, { MatchEvent(minute: 32, type: .goal, player: "B. Mbeumo", team: .home, description: nil, score: "2-0") }),
        (45, { MatchEvent(minute: 45, type: .halfTime, player: nil, team: .home, description: nil, score: "2-0") }),
        (47, { MatchEvent(minute: 47, type: .goal, player: "J. Kluivert", team: .away, description: nil, score: "2-1") }),
        (58, { MatchEvent(minute: 58, type: .substitution(on: "Bruno Fernandes", off: "A. Diallo"), player: "Bruno Fernandes", team: .home, description: nil, score: nil) }),
        (65, { MatchEvent(minute: 65, type: .yellowCard, player: "Álex Jiménez", team: .away, description: nil, score: nil) }),
        (72, { MatchEvent(minute: 72, type: .goal, player: "Matheus Cunha", team: .home, description: nil, score: "3-1") }),
        (78, { MatchEvent(minute: 78, type: .substitution(on: "M. Mount", off: "B. Mbeumo"), player: "M. Mount", team: .home, description: nil, score: nil) }),
        (85, { MatchEvent(minute: 85, type: .redCard, player: "T. Adams", team: .away, description: nil, score: nil) }),
        (90, { MatchEvent(minute: 90, type: .fullTime, player: nil, team: .home, description: nil, score: "3-1") })
    ]
    
    func startSimulation() {
        guard !isPlaying else { return }
        isPlaying = true
        
        // Timer para minutos
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.currentMinute < self.matchDuration {
                    self.currentMinute += 1
                    self.checkForEvents()
                } else {
                    self.stopSimulation()
                }
            }
        }
        
        // Agregar evento inicial
        if let firstEvent = simulatedEvents.first {
            events.append(firstEvent.event())
        }
    }
    
    func stopSimulation() {
        timer?.invalidate()
        eventTimer?.invalidate()
        timer = nil
        eventTimer = nil
        isPlaying = false
    }
    
    func pauseSimulation() {
        timer?.invalidate()
        eventTimer?.invalidate()
        isPlaying = false
    }
    
    func resetSimulation() {
        stopSimulation()
        currentMinute = 0
        homeScore = 0
        awayScore = 0
        events = []
    }
    
    private func checkForEvents() {
        // Buscar eventos que deben ocurrir en este minuto
        for simulatedEvent in simulatedEvents {
            if simulatedEvent.minute == currentMinute {
                let event = simulatedEvent.event()
                events.append(event)
                
                // Actualizar marcador si es un gol
                if case .goal = event.type {
                    if event.team == .home {
                        homeScore += 1
                    } else {
                        awayScore += 1
                    }
                }
                
                // Notificar evento
                NotificationCenter.default.post(
                    name: NSNotification.Name("MatchEventOccurred"),
                    object: event
                )
            }
        }
    }
    
    func getCurrentScore() -> String {
        return "\(homeScore)-\(awayScore)"
    }
}


