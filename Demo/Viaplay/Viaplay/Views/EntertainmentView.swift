//
//  EntertainmentView.swift
//  Viaplay
//
//  Vista principal para mostrar componentes de entretenimiento interactivo
//

import SwiftUI

struct EntertainmentView: View {
    @StateObject private var entertainmentManager = EntertainmentManager(userId: "viaplay-user-123")
    @Environment(\.dismiss) private var dismiss
    @State private var showingOverlay = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: "1B1B25"),
                        Color(hex: "1F1E26")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerSection
                        
                        // Stats Cards
                        statsSection
                        
                        // Active Components
                        if !entertainmentManager.activeComponents.isEmpty {
                            componentsSection(
                                title: "Activos Ahora",
                                components: entertainmentManager.activeComponents,
                                color: .green,
                                icon: "play.circle.fill"
                            )
                        }
                        
                        // Upcoming Components
                        if !entertainmentManager.upcomingComponents.isEmpty {
                            componentsSection(
                                title: "Próximamente",
                                components: entertainmentManager.upcomingComponents,
                                color: .orange,
                                icon: "clock.fill"
                            )
                        }
                        
                        // Completed Components
                        if !entertainmentManager.completedComponents.isEmpty {
                            componentsSection(
                                title: "Completados",
                                components: entertainmentManager.completedComponents,
                                color: .blue,
                                icon: "checkmark.circle.fill"
                            )
                        }
                        
                        // Empty State
                        if entertainmentManager.activeComponents.isEmpty &&
                           entertainmentManager.upcomingComponents.isEmpty &&
                           entertainmentManager.completedComponents.isEmpty {
                            emptyState
                        }
                        
                        // Action Buttons
                        actionButtonsSection
                    }
                    .padding()
                }
                
                // Entertainment Overlay (simulating video player)
                if showingOverlay {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showingOverlay = false
                            }
                        }
                    
                    EntertainmentOverlay(manager: entertainmentManager)
                }
            }
            .navigationTitle("Entretenimiento Interactivo")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await entertainmentManager.loadComponents()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .task {
            await entertainmentManager.loadComponents()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("Componentes Interactivos")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Participa en trivia, encuestas y más durante las transmisiones")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(
                title: "Activos",
                value: "\(entertainmentManager.activeComponents.count)",
                icon: "play.circle.fill",
                color: .green
            )
            
            statCard(
                title: "Próximos",
                value: "\(entertainmentManager.upcomingComponents.count)",
                icon: "clock.fill",
                color: .orange
            )
            
            statCard(
                title: "Puntos",
                value: "\(entertainmentManager.userScore)",
                icon: "star.fill",
                color: .yellow
            )
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Components Section
    
    private func componentsSection(
        title: String,
        components: [InteractiveComponent],
        color: Color,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(components.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(color)
                    .clipShape(Circle())
            }
            
            ForEach(components) { component in
                InteractiveComponentCard(
                    component: component,
                    hasResponded: entertainmentManager.hasUserResponded(to: component.id),
                    showResults: entertainmentManager.hasUserResponded(to: component.id) || component.state == .completed,
                    onOptionSelected: { optionId in
                        handleResponse(componentId: component.id, optionId: optionId)
                    }
                )
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No hay componentes activos")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Los componentes interactivos aparecerán aquí durante las transmisiones en vivo")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Text("Acciones")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                withAnimation {
                    showingOverlay.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "play.rectangle.fill")
                    Text("Simular Video Player Overlay")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button {
                Task {
                    await entertainmentManager.refreshLeaderboard()
                }
            } label: {
                HStack {
                    Image(systemName: "list.number")
                    Text("Ver Tabla de Posiciones")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding(.top)
    }
    
    // MARK: - Methods
    
    private func handleResponse(componentId: String, optionId: String) {
        Task {
            do {
                try await entertainmentManager.submitResponse(
                    componentId: componentId,
                    selectedOptions: [optionId]
                )
            } catch {
                print("❌ Error submitting response: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EntertainmentView()
        .preferredColorScheme(.dark)
}


