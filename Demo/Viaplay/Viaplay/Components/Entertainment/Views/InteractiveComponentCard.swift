//
//  InteractiveComponentCard.swift
//  Viaplay
//
//  Card view for displaying interactive entertainment components
//  Structure designed to be portable to ReachuSDK
//

import SwiftUI
import Combine

/// Card view for interactive components
public struct InteractiveComponentCard: View {
    
    let component: InteractiveComponent
    let onOptionSelected: (String) -> Void
    let hasResponded: Bool
    let showResults: Bool
    
    @State private var selectedOptions: Set<String> = []
    @State private var isExpanded: Bool = false
    @State private var timeRemaining: TimeInterval?
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    public init(
        component: InteractiveComponent,
        hasResponded: Bool = false,
        showResults: Bool = false,
        onOptionSelected: @escaping (String) -> Void
    ) {
        self.component = component
        self.hasResponded = hasResponded
        self.showResults = showResults
        self.onOptionSelected = onOptionSelected
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerView
            
            // Description
            if let description = component.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Time remaining
            if let timeRemaining = timeRemaining, component.state == .active {
                timeRemainingView
            }
            
            // Options
            optionsView
            
            // Submit button (if not responded)
            if !hasResponded && component.state == .active && !selectedOptions.isEmpty {
                submitButton
            }
            
            // Results (if responded or component completed)
            if showResults || component.state == .completed {
                resultsView
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onReceive(timer) { _ in
            updateTimeRemaining()
        }
        .onAppear {
            updateTimeRemaining()
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            // Icon
            Image(systemName: component.type.iconName)
                .font(.title2)
                .foregroundColor(componentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(component.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    // Type badge
                    Text(component.type.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(componentColor.opacity(0.2))
                        .foregroundColor(componentColor)
                        .cornerRadius(8)
                    
                    // State badge
                    Text(component.state.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(stateColor.opacity(0.2))
                        .foregroundColor(stateColor)
                        .cornerRadius(8)
                    
                    // Points (if applicable)
                    if let points = component.points {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                            Text("\(points)")
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private var timeRemainingView: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(.orange)
            
            if let remaining = timeRemaining {
                Text(formatTimeRemaining(remaining))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var optionsView: some View {
        VStack(spacing: 12) {
            ForEach(component.options) { option in
                optionButton(option)
            }
        }
    }
    
    private func optionButton(_ option: InteractionOption) -> some View {
        Button {
            handleOptionSelection(option.id)
        } label: {
            HStack {
                // Emoji or icon
                if let emoji = option.emoji {
                    Text(emoji)
                        .font(.title2)
                }
                
                // Option text
                Text(option.text)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Selection indicator
                if selectedOptions.contains(option.id) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(componentColor)
                }
                
                // Correct indicator (if showing results)
                if showResults || component.state == .completed {
                    if option.isCorrect == true {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedOptions.contains(option.id) ? componentColor : Color.gray.opacity(0.3),
                        lineWidth: selectedOptions.contains(option.id) ? 2 : 1
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedOptions.contains(option.id) ? componentColor.opacity(0.1) : Color.clear)
                    )
            )
        }
        .disabled(hasResponded || component.state != .active)
    }
    
    private var submitButton: some View {
        Button {
            submitResponse()
        } label: {
            HStack {
                Image(systemName: "paperplane.fill")
                Text("Enviar Respuesta")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(componentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    private var resultsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resultados")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(component.options) { option in
                resultBar(for: option)
            }
        }
        .padding(.top, 8)
    }
    
    private func resultBar(for option: InteractionOption) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let emoji = option.emoji {
                    Text(emoji)
                }
                Text(option.text)
                    .font(.subheadline)
                Spacer()
                Text("\(option.voteCount) votos")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let percentage = option.percentage {
                    Text(String(format: "%.1f%%", percentage))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(componentColor)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(option.isCorrect == true ? Color.green : componentColor)
                        .frame(width: geometry.size.width * CGFloat((option.percentage ?? 0) / 100))
                }
            }
            .frame(height: 8)
        }
    }
    
    // MARK: - Computed Properties
    
    private var componentColor: Color {
        switch component.type {
        case .trivia: return .blue
        case .quiz: return .purple
        case .poll: return .orange
        case .prediction: return .pink
        case .reaction: return .red
        case .voting: return .green
        case .challenge: return .indigo
        case .leaderboard: return .cyan
        }
    }
    
    private var stateColor: Color {
        switch component.state {
        case .upcoming: return .gray
        case .active: return .green
        case .completed: return .blue
        case .expired: return .red
        }
    }
    
    // MARK: - Methods
    
    private func handleOptionSelection(_ optionId: String) {
        if component.allowMultipleResponses {
            if selectedOptions.contains(optionId) {
                selectedOptions.remove(optionId)
            } else {
                selectedOptions.insert(optionId)
            }
        } else {
            selectedOptions = [optionId]
        }
    }
    
    private func submitResponse() {
        guard let firstOption = selectedOptions.first else { return }
        onOptionSelected(firstOption)
    }
    
    private func updateTimeRemaining() {
        guard let endTime = component.endTime else {
            timeRemaining = nil
            return
        }
        
        let remaining = endTime.timeIntervalSinceNow
        timeRemaining = remaining > 0 ? remaining : 0
    }
    
    private func formatTimeRemaining(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            InteractiveComponentCard(
                component: InteractiveComponent(
                    id: "preview-1",
                    type: .trivia,
                    state: .active,
                    title: "¿Quién ganó el último Mundial?",
                    description: "Pregunta de trivia sobre fútbol",
                    endTime: Date().addingTimeInterval(300),
                    interactionType: .singleChoice,
                    options: [
                        InteractionOption(id: "1", text: "Argentina", value: "arg", emoji: "🇦🇷", isCorrect: true),
                        InteractionOption(id: "2", text: "Francia", value: "fra", emoji: "🇫🇷", isCorrect: false),
                        InteractionOption(id: "3", text: "Brasil", value: "bra", emoji: "🇧🇷", isCorrect: false)
                    ],
                    points: 10
                ),
                onOptionSelected: { _ in }
            )
            
            InteractiveComponentCard(
                component: InteractiveComponent(
                    id: "preview-2",
                    type: .poll,
                    state: .active,
                    title: "¿Cuál es tu equipo favorito?",
                    interactionType: .singleChoice,
                    options: [
                        InteractionOption(id: "1", text: "Real Madrid", value: "rm", emoji: "⚪", voteCount: 45, percentage: 45),
                        InteractionOption(id: "2", text: "Barcelona", value: "fcb", emoji: "🔵", voteCount: 35, percentage: 35),
                        InteractionOption(id: "3", text: "Atlético", value: "atm", emoji: "🔴", voteCount: 20, percentage: 20)
                    ]
                ),
                showResults: true,
                onOptionSelected: { _ in }
            )
        }
        .padding()
    }
}

