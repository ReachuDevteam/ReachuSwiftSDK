//
//  WebSocketManager.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import Foundation
import Combine
import SwiftUI

// MARK: - WebSocket Manager
class WebSocketManager: ObservableObject {
    @Published var currentPoll: Poll?
    @Published var currentProduct: Product?
    @Published var currentContest: Contest?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()
    
    func connect() {
        print("🔌 [WebSocketManager] Connecting to WebSocket...")
        
        // Simulate WebSocket connection with local data
        // In a real app, this would connect to your WebSocket server
        simulateLiveEvents()
    }
    
    func disconnect() {
        print("🔌 [WebSocketManager] Disconnecting from WebSocket...")
        webSocketTask?.cancel()
        webSocketTask = nil
    }
    
    private func simulateLiveEvents() {
        // Simulate poll after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.currentPoll = Poll.mockPoll
        }
        
        // Simulate product after 15 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            self.currentProduct = Product.mockProduct
        }
        
        // Simulate contest after 25 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
            self.currentContest = Contest.mockContest
        }
    }
}

// MARK: - Poll Model
struct Poll: Identifiable {
    let id = UUID()
    let question: String
    let options: [PollOption]
    let duration: Int // in seconds
    let isActive: Bool
    
    static let mockPoll = Poll(
        question: "Hvem vinner kampen?",
        options: [
            PollOption(text: "Barcelona", percentage: 45),
            PollOption(text: "PSG", percentage: 35),
            PollOption(text: "Uavgjort", percentage: 20)
        ],
        duration: 30,
        isActive: true
    )
}

struct PollOption: Identifiable {
    let id = UUID()
    let text: String
    let percentage: Int
}

// MARK: - Product Model
struct Product: Identifiable {
    let id = UUID()
    let name: String
    let price: String
    let imageURL: String
    let description: String
    
    static let mockProduct = Product(
        name: "Barcelona Jersey 2024",
        price: "899 kr",
        imageURL: "https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=300",
        description: "Official Barcelona home jersey for the 2024 season"
    )
}

// MARK: - Contest Model
struct Contest: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let prize: String
    let imageURL: String
    
    static let mockContest = Contest(
        title: "Gjett resultatet!",
        description: "Gjett det endelige resultatet og vinn en Barcelona-trøye",
        prize: "Barcelona Jersey + 1000 kr",
        imageURL: "https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=300"
    )
}

// MARK: - Overlay Views
struct PollOverlay: View {
    let poll: Poll
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text(poll.question)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                ForEach(poll.options) { option in
                    Button(action: {}) {
                        HStack {
                            Text(option.text)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(option.percentage)%")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
            }
            
            Button(action: onDismiss) {
                Text("Lukk")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(16)
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
    }
}

struct ProductOverlay: View {
    let product: Product
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: product.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 80, height: 80)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(product.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                
                Text(product.price)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.96, green: 0.08, blue: 0.42))
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
    }
}

struct ContestOverlay: View {
    let contest: Contest
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: contest.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(height: 120)
            .cornerRadius(8)
            
            VStack(spacing: 8) {
                Text(contest.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(contest.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Text("Premie: \(contest.prize)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.96, green: 0.08, blue: 0.42))
            }
            
            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("Delta")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.96, green: 0.08, blue: 0.42))
                        .cornerRadius(8)
                }
                
                Button(action: onDismiss) {
                    Text("Lukk")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
    }
}
