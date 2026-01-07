//
//  EntertainmentOverlay.swift
//  Viaplay
//
//  Overlay view for displaying entertainment components during video playback
//  Structure designed to be portable to ReachuSDK
//

import SwiftUI

/// Overlay view for entertainment components
public struct EntertainmentOverlay: View {
    
    @ObservedObject var manager: EntertainmentManager
    @State private var selectedComponent: InteractiveComponent?
    @State private var showingFullView: Bool = false
    @State private var isMinimized: Bool = false
    
    public init(manager: EntertainmentManager) {
        self.manager = manager
    }
    
    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Active component notification
            if let activeComponent = manager.activeComponents.first, !showingFullView {
                componentNotification(activeComponent)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            
            // Full view sheet
            if showingFullView {
                fullComponentView
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(), value: showingFullView)
        .animation(.spring(), value: manager.activeComponents.count)
    }
    
    // MARK: - Subviews
    
    private func componentNotification(_ component: InteractiveComponent) -> some View {
        Button {
            withAnimation {
                selectedComponent = component
                showingFullView = true
            }
        } label: {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: component.type.iconName)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(componentColor(for: component.type))
                    .clipShape(Circle())
                
                if !isMinimized {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(component.type.displayName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(component.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    Image(systemName: "chevron.up")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, isMinimized ? 12 : 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: isMinimized ? 30 : 16)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: isMinimized ? 30 : 16)
                            .stroke(componentColor(for: component.type), lineWidth: 2)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.trailing, 16)
        .padding(.bottom, 100)
    }
    
    private var fullComponentView: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 6)
                .padding(.top, 12)
            
            // Header
            HStack {
                Text("Componentes Interactivos")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Active count badge
                if !manager.activeComponents.isEmpty {
                    Text("\(manager.activeComponents.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                
                Button {
                    withAnimation {
                        showingFullView = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Active components
                    if !manager.activeComponents.isEmpty {
                        sectionHeader("Activos", color: .green)
                        
                        ForEach(manager.activeComponents) { component in
                            InteractiveComponentCard(
                                component: component,
                                hasResponded: manager.hasUserResponded(to: component.id),
                                showResults: manager.hasUserResponded(to: component.id),
                                onOptionSelected: { optionId in
                                    handleResponse(componentId: component.id, optionId: optionId)
                                }
                            )
                        }
                    }
                    
                    // Upcoming components
                    if !manager.upcomingComponents.isEmpty {
                        sectionHeader("Próximamente", color: .orange)
                        
                        ForEach(manager.upcomingComponents) { component in
                            InteractiveComponentCard(
                                component: component,
                                onOptionSelected: { _ in }
                            )
                        }
                    }
                    
                    // Completed components
                    if !manager.completedComponents.isEmpty {
                        sectionHeader("Completados", color: .blue)
                        
                        ForEach(manager.completedComponents) { component in
                            InteractiveComponentCard(
                                component: component,
                                hasResponded: true,
                                showResults: true,
                                onOptionSelected: { _ in }
                            )
                        }
                    }
                    
                    // Empty state
                    if manager.activeComponents.isEmpty &&
                       manager.upcomingComponents.isEmpty &&
                       manager.completedComponents.isEmpty {
                        emptyState
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: -5)
        )
        .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 100 {
                        withAnimation {
                            showingFullView = false
                        }
                    }
                }
        )
    }
    
    private func sectionHeader(_ title: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Spacer()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No hay componentes activos")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Los componentes interactivos aparecerán aquí durante la transmisión")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Methods
    
    private func handleResponse(componentId: String, optionId: String) {
        Task {
            do {
                try await manager.submitResponse(
                    componentId: componentId,
                    selectedOptions: [optionId]
                )
            } catch {
                print("Error submitting response: \(error)")
            }
        }
    }
    
    private func componentColor(for type: EntertainmentComponentType) -> Color {
        switch type {
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
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        EntertainmentOverlay(manager: EntertainmentManager(userId: "preview-user"))
    }
}


