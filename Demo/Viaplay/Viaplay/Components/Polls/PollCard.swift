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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image("icon ")  // Viaplay icon from assets
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                
                Text("9m")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("AVSTEMNING")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Question
            Text(component.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
            
            // Options
            VStack(spacing: 8) {
                ForEach(component.options) { option in
                    PollOptionButton(
                        option: option,
                        isDisabled: hasResponded,
                        onTap: { onVote(option.id) }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.2))
        )
    }
}

// MARK: - Poll Option Button

private struct PollOptionButton: View {
    let option: InteractionOption
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(option.text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(isDisabled ? 0.05 : 0.1))
            )
        }
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


