//
//  PollCard.swift
//  Viaplay
//
//  Molecular component: Poll/voting card
//

import SwiftUI

struct PollCard: View {
    let component: InteractiveComponent
    let hasResponded: Bool
    let onVote: (String) -> Void
    
    @State private var selectedOption: String?
    @State private var showSuccessAnimation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header (like tweet/highlight style)
            HStack(spacing: 8) {
                // Avatar with initials
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.purple.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Text("AS")  // Poll avatar initials
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Viaplay Avstemning")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text("Direktesending")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Text("9m")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // XXL Sports sponsor
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Sponset av")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Image("logo1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 50, maxHeight: 16)
                }
            }
            
            // Question
            Text(component.title)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(1)
            
            // Options
            VStack(spacing: 8) {
                ForEach(component.options) { option in
                    PollOptionButton(
                        option: option,
                        isSelected: selectedOption == option.id,
                        isDisabled: hasResponded,
                        showSuccess: showSuccessAnimation && selectedOption == option.id,
                        onTap: {
                            selectedOption = option.id
                            onVote(option.id)
                            
                            // Success animation
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                showSuccessAnimation = true
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    showSuccessAnimation = false
                                }
                            }
                        }
                    )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.4),
                                    Color.purple.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Poll Option Button

private struct PollOptionButton: View {
    let option: InteractionOption
    let isSelected: Bool
    let isDisabled: Bool
    let showSuccess: Bool
    let onTap: () -> Void
    
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                scale = 0.97
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
            onTap()
        }) {
            HStack {
                Text(option.text)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if showSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected 
                        ? Color.purple.opacity(0.25)
                        : Color.white.opacity(isDisabled ? 0.05 : 0.08)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected 
                                ? Color.purple.opacity(0.5)
                                : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .scaleEffect(scale)
        .disabled(isDisabled)
    }
}

#Preview {
    PollCard(
        component: InteractiveComponent(
            id: "poll-1",
            type: .poll,
            state: .active,
            title: "¿Cuál es tu equipo favorito?",
            interactionType: .singleChoice,
            options: [
                InteractionOption(id: "opt1", text: "Real Madrid", value: "real"),
                InteractionOption(id: "opt2", text: "Barcelona", value: "barca"),
                InteractionOption(id: "opt3", text: "Atlético", value: "atleti")
            ]
        ),
        hasResponded: false,
        onVote: { _ in }
    )
    .padding()
    .background(Color(hex: "1B1B25"))
}


