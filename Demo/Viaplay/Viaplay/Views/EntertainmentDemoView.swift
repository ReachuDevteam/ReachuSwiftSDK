//
//  EntertainmentDemoView.swift
//  Viaplay
//
//  Demo view showcasing entertainment components
//

import SwiftUI

struct EntertainmentDemoView: View {
    
    @StateObject private var entertainmentManager = EntertainmentManager(userId: "demo-user-123")
    @State private var showingOverlay = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Stats cards
                        statsSection
                        
                        // Active components
                        if !entertainmentManager.activeComponents.isEmpty {
                            componentsSection(
                                title: "Componentes Activos",
                                components: entertainmentManager.activeComponents,
                                color: .green
                            )
                        }
                        
                        // Upcoming components
                        if !entertainmentManager.upcomingComponents.isEmpty {
                            componentsSection(
                                title: "Próximamente",
                                components: entertainmentManager.upcomingComponents,
                                color: .orange
                            )
                        }
                        
                        // Completed components
                        if !entertainmentManager.completedComponents.isEmpty {
                            componentsSection(
                                title: "Completados",
                                components: entertainmentManager.completedComponents,
                                color: .blue
                            )
                        }
                        
                        // Demo actions
                        demoActionsSection
                    }
                    .padding()
                }
                
                // Entertainment overlay (simulating video player overlay)
                if showingOverlay {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showingOverlay = false
                            }
                        }
                    
                    EntertainmentOverlay(manager: entertainmentManager)
                }
            }
            .navigationTitle("Entertainment Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await entertainmentManager.loadComponents()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await entertainmentManager.loadComponents()
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Componentes Interactivos")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Experimenta con trivia, encuestas y más")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
    }
    
    private var statsSection: some View {
        HStack(spacing: 16) {
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
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }
    
    private func componentsSection(
        title: String,
        components: [InteractiveComponent],
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Spacer()
                
                Text("\(components.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(color)
                    .clipShape(Circle())
            }
            
            ForEach(components) { component in
                InteractiveComponentCard(
                    component: component,
                    hasResponded: entertainmentManager.hasUserResponded(to: component.id),
                    showResults: entertainmentManager.hasUserResponded(to: component.id),
                    onOptionSelected: { optionId in
                        handleResponse(componentId: component.id, optionId: optionId)
                    }
                )
            }
        }
    }
    
    private var demoActionsSection: some View {
        VStack(spacing: 16) {
            Text("Acciones de Demo")
                .font(.headline)
                .foregroundColor(.secondary)
            
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
            
            Button {
                Task {
                    await entertainmentManager.loadComponents()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Recargar Componentes")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
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
                print("Error submitting response: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EntertainmentDemoView()
}


