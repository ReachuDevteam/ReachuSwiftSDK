//
//  LiveMatchView.swift
//  Viaplay
//
//  Vista simulando partido live en TV con chat e interactivos
//

import SwiftUI
import AVKit
import AVFoundation
import Combine

struct LiveMatchView: View {
    let match: Match
    let onDismiss: () -> Void
    
    @StateObject private var playerViewModel = VideoPlayerViewModel()
    @StateObject private var entertainmentManager = EntertainmentManager(userId: "viaplay-user-123")
    @StateObject private var chatManager = ChatManager()
    @StateObject private var matchSimulation = MatchSimulationManager()
    @State private var selectedTab: MatchTab = .all
    @State private var isLoadingVideo = true
    @State private var selectedMinute: Int? = nil // nil = LIVE, Int = minuto específico
    
    enum MatchTab: String, CaseIterable {
        case all = "All"
        case chat = "Chat"
        case highlights = "Highlights"
        case liveScores = "Live Scores"
        case polls = "Polls"
        case statistics = "Statistics"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .chat: return "message"
            case .highlights: return "play.rectangle"
            case .liveScores: return "trophy"
            case .polls: return "clock"
            case .statistics: return "chart.bar"
            }
        }
    }
    
    @State private var matchStatistics = MatchStatistics.mock(for: Match.barcelonaPSG)
    @State private var leagueTable = LeagueTable.premierLeague
    
    // Timeline dinámico basado en simulación
    private var matchTimeline: MatchTimeline {
        MatchTimeline(events: matchSimulation.events)
    }
    
    // Minuto actual para filtrar contenido
    private var currentFilterMinute: Int {
        selectedMinute ?? matchSimulation.currentMinute
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(hex: "1B1B25").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with match info (no video, video está en TV)
                    matchHeaderSection
                        .frame(width: geometry.size.width)
                        .padding(.top, 8)
                    
                    // Sponsor Banner
                    sponsorBanner
                        .frame(width: geometry.size.width)
                    
                    // Navigation Tabs
                    navigationTabs
                        .frame(width: geometry.size.width)
                    
                    // Interactive Content Section
                    interactiveContentSection
                        .frame(maxHeight: .infinity)
                    
                    // Video Controls (at bottom, video is on TV)
                    videoControlsSection
                        .frame(width: geometry.size.width)
                }
                .frame(width: geometry.size.width)
            }
        }
        .navigationBarHidden(true)
        .onReceive(matchSimulation.$events) { _ in
            // Trigger view update when events change
        }
        .onReceive(matchSimulation.$currentMinute) { _ in
            // Trigger view update when minute changes
        }
        .onAppear {
            playerViewModel.setupPlayer()
            chatManager.startSimulation()
            matchSimulation.startSimulation()
            Task {
                await entertainmentManager.loadComponents()
            }
        }
        .onDisappear {
            playerViewModel.cleanup()
            chatManager.stopSimulation()
            matchSimulation.stopSimulation()
        }
    }
    
    // MARK: - Match Header Section
    
    private var matchHeaderSection: some View {
        VStack(spacing: 16) {
            // Back button
            HStack {
                Button {
                    onDismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Match Score and Teams
            HStack(spacing: 16) {
                // Home Team
                VStack(spacing: 8) {
                    AsyncImage(url: URL(string: "https://upload.wikimedia.org/wikipedia/en/thumb/4/47/FC_Barcelona_%28crest%29.svg/200px-FC_Barcelona_%28crest%29.svg.png")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .overlay(Text("FCB").foregroundColor(.white).font(.system(size: 14, weight: .bold)))
                    }
                    .frame(width: 60, height: 60)
                    
                    Text(match.homeTeam.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                
                    // Score
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Text("\(matchSimulation.homeScore)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text("\(matchSimulation.awayScore)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text("\(matchSimulation.currentMinute)'")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Away Team
                VStack(spacing: 8) {
                    AsyncImage(url: URL(string: "https://upload.wikimedia.org/wikipedia/en/thumb/a/a7/Paris_Saint-Germain_F.C..svg/200px-Paris_Saint-Germain_F.C..svg.png")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .overlay(Text("PSG").foregroundColor(.white).font(.system(size: 14, weight: .bold)))
                    }
                    .frame(width: 60, height: 60)
                    
                    Text(match.awayTeam.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            
            // Match Details
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "soccerball")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(match.competition)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(match.venue)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Video Controls Section (at bottom, video on TV)
    
    private var videoControlsSection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.2))
            
            VStack(spacing: 12) {
                // Timeline Scrubber
                timelineScrubber
                
                // Controls
                HStack(spacing: 20) {
                    // Time / Minute
                    if let selectedMinute = selectedMinute {
                        Text("\(selectedMinute)'")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    } else {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("LIVE")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    // Play/Pause
                    Button(action: { playerViewModel.togglePlayPause() }) {
                        Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }
                    
                    Spacer()
                    
                    // Mute/Unmute
                    Button(action: { playerViewModel.toggleMute() }) {
                        Image(systemName: playerViewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
            .background(Color(hex: "1F1E26"))
        }
    }
    
    // MARK: - Timeline Scrubber
    
    private var timelineScrubber: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Progress track (hasta el minuto actual o seleccionado)
                    let progress = selectedMinute != nil 
                        ? CGFloat(selectedMinute!) / CGFloat(90)
                        : CGFloat(matchSimulation.currentMinute) / CGFloat(90)
                    
                    Rectangle()
                        .fill(Color(red: 0.96, green: 0.08, blue: 0.42))
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                    
                    // Event markers
                    ForEach(matchTimeline.events, id: \.id) { event in
                        let position = CGFloat(event.minute) / CGFloat(90)
                        Circle()
                            .fill(eventMarkerColor(for: event.type))
                            .frame(width: 8, height: 8)
                            .offset(x: geometry.size.width * position - 4)
                    }
                    
                    // Highlight markers (cada 10 minutos)
                    ForEach(Array(stride(from: 10, through: min(matchSimulation.currentMinute, 90), by: 10)), id: \.self) { minute in
                        let position = CGFloat(minute) / CGFloat(90)
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                            .offset(x: geometry.size.width * position - 5)
                    }
                    
                    // Thumb (handle)
                    let thumbPosition = selectedMinute != nil
                        ? CGFloat(selectedMinute!) / CGFloat(90)
                        : CGFloat(matchSimulation.currentMinute) / CGFloat(90)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .offset(x: geometry.size.width * thumbPosition - 8)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let percentage = max(0, min(1, value.location.x / geometry.size.width))
                                    let minute = Int(percentage * CGFloat(90))
                                    selectedMinute = minute
                                }
                                .onEnded { _ in
                                    // Mantener seleccionado o volver a LIVE
                                }
                        )
                }
            }
            .frame(height: 20)
            
            // Minute labels
            HStack {
                Text("0'")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                if selectedMinute == nil {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.red)
                    }
                } else {
                    Text("\(selectedMinute!)'")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Button {
                        selectedMinute = nil // Volver a LIVE
                    } label: {
                        Text("LIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                Text("90'")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
    }
    
    private func eventMarkerColor(for eventType: MatchEvent.EventType) -> Color {
        switch eventType {
        case .goal:
            return .green
        case .yellowCard:
            return .yellow
        case .redCard:
            return .red
        case .substitution:
            return .blue
        default:
            return .white.opacity(0.6)
        }
    }
    
    // MARK: - Sponsor Banner
    
    private var sponsorBanner: some View {
        HStack {
            Text("Sponset av")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Image("logo1")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 20)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "1F1E26"))
    }
    
    // MARK: - Navigation Tabs
    
    private var navigationTabs: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 6)
                .padding(.top, 8)
                .padding(.bottom, 4)
            
            HStack(spacing: 0) {
                ForEach(MatchTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: .regular))
                                .foregroundStyle(
                                    selectedTab == tab 
                                    ? Color(red: 0.96, green: 0.08, blue: 0.42) 
                                    : Color.white.opacity(0.6)
                                )
                            
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                }
            }
        }
        .background(Color(hex: "1F1E26"))
    }
    
    // MARK: - Interactive Content Section
    
    private var interactiveContentSection: some View {
        GeometryReader { geometry in
            Group {
                switch selectedTab {
                case .all:
                    allContentMixView
                        .frame(width: geometry.size.width, height: geometry.size.height)
                case .chat:
                    chatContentView
                        .frame(width: geometry.size.width, height: geometry.size.height)
                case .highlights:
                    highlightsContentView
                        .frame(width: geometry.size.width, height: geometry.size.height)
                case .liveScores:
                    liveScoresContentView
                        .frame(width: geometry.size.width, height: geometry.size.height)
                case .polls:
                    pollsContentView
                        .frame(width: geometry.size.width, height: geometry.size.height)
                case .statistics:
                    MatchStatsView(statistics: matchStatistics)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
    }
    
    // MARK: - All Content Mix View
    
    private var allContentMixView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Mezclar todo: eventos, chat, polls, stats intercalados
                ForEach(mixedContentItems, id: \.id) { item in
                    switch item.type {
                    case .timelineEvent:
                        if let event = item.event {
                            timelineEventCard(event)
                        } else {
                            EmptyView()
                        }
                    case .chatMessage:
                        if let message = item.chatMessage {
                            chatMessageRow(message)
                        } else {
                            EmptyView()
                        }
                    case .poll:
                        if let poll = item.poll {
                            pollCard(poll)
                        } else {
                            EmptyView()
                        }
                    case .statistics:
                        statisticsPreviewCard
                    case .highlight:
                        highlightCard(item.highlightIndex ?? 0)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(hex: "1B1B25"))
    }
    
    // MARK: - Mixed Content Items
    
    private struct MixedContentItem: Identifiable {
        let id = UUID()
        let type: ContentType
        let timestamp: Date
        let event: MatchEvent?
        let chatMessage: ChatMessage?
        let poll: InteractiveComponent?
        let highlightIndex: Int?
        
        enum ContentType {
            case timelineEvent
            case chatMessage
            case poll
            case statistics
            case highlight
        }
    }
    
    private var mixedContentItems: [MixedContentItem] {
        var items: [MixedContentItem] = []
        
        // Filtrar eventos hasta el minuto seleccionado
        let filteredEvents = matchTimeline.events.filter { $0.minute <= currentFilterMinute }
        
        // Agregar eventos del timeline
        for event in filteredEvents.reversed() {
            items.append(MixedContentItem(
                type: .timelineEvent,
                timestamp: Date().addingTimeInterval(-Double((currentFilterMinute - event.minute) * 60)),
                event: event,
                chatMessage: nil,
                poll: nil,
                highlightIndex: nil
            ))
        }
        
        // Agregar mensajes de chat hasta el minuto seleccionado
        // Simular que los mensajes aparecen progresivamente
        let chatMessages = chatManager.messages.filter { message in
            // Estimar el minuto del mensaje basado en su posición
            let messageIndex = chatManager.messages.firstIndex(where: { $0.id == message.id }) ?? 0
            let estimatedMinute = (messageIndex * currentFilterMinute) / max(chatManager.messages.count, 1)
            return estimatedMinute <= currentFilterMinute
        }
        
        for message in chatMessages {
            items.append(MixedContentItem(
                type: .chatMessage,
                timestamp: message.timestamp,
                event: nil,
                chatMessage: message,
                poll: nil,
                highlightIndex: nil
            ))
        }
        
        // Agregar polls activos hasta el minuto seleccionado
        let filteredPolls = entertainmentManager.activeComponents.filter { component in
            guard component.type == .poll, let startTime = component.startTime else { return false }
            // Estimar minuto del poll
            let timeDiff = Date().timeIntervalSince(startTime)
            let pollMinute = Int(timeDiff / 60)
            return pollMinute <= currentFilterMinute
        }
        
        for poll in filteredPolls {
            items.append(MixedContentItem(
                type: .poll,
                timestamp: poll.startTime ?? Date(),
                event: nil,
                chatMessage: nil,
                poll: poll,
                highlightIndex: nil
            ))
        }
        
        // Agregar highlights hasta el minuto seleccionado (cada 10 minutos)
        for minute in stride(from: 10, through: currentFilterMinute, by: 10) {
            items.append(MixedContentItem(
                type: .highlight,
                timestamp: Date().addingTimeInterval(-Double((currentFilterMinute - minute) * 60)),
                event: nil,
                chatMessage: nil,
                poll: nil,
                highlightIndex: minute / 10
            ))
        }
        
        // Agregar estadísticas cada 15 minutos hasta el minuto seleccionado
        for minute in stride(from: 15, through: currentFilterMinute, by: 15) {
            items.append(MixedContentItem(
                type: .statistics,
                timestamp: Date().addingTimeInterval(-Double((currentFilterMinute - minute) * 60)),
                event: nil,
                chatMessage: nil,
                poll: nil,
                highlightIndex: nil
            ))
        }
        
        // Ordenar por timestamp (más reciente primero)
        return items.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Timeline Event Card
    
    private func timelineEventCard(_ event: MatchEvent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Minute badge
            VStack(spacing: 0) {
                Text("\(event.minute)'")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 50)
                
                // Línea vertical conectando eventos
                if let nextEvent = matchTimeline.events.first(where: { $0.minute > event.minute }) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 2)
                        .frame(height: 40)
                }
            }
            
            // Event content
            VStack(alignment: .leading, spacing: 8) {
                eventContentView(event)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    @ViewBuilder
    private func eventContentView(_ event: MatchEvent) -> some View {
        switch event.type {
        case .goal:
            HStack(spacing: 8) {
                if let player = event.player {
                    Text(player)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Image(systemName: "soccerball")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                
                if let score = event.score {
                    Text(score)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
        case .substitution(let on, let off):
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    
                    Text(on)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                    
                    Text(off)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
        case .yellowCard:
            HStack(spacing: 8) {
                if let player = event.player {
                    Text(player)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 20, height: 24)
                    .cornerRadius(3)
            }
            
        case .redCard:
            HStack(spacing: 8) {
                if let player = event.player {
                    Text(player)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 20, height: 24)
                    .cornerRadius(3)
            }
            
        case .kickOff:
            HStack(spacing: 8) {
                Image(systemName: "whistle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Text("Kick-off")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
            }
            
        case .halfTime:
            Text("Half Time")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
        case .fullTime:
            Text("Full Time")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
        default:
            if let description = event.description {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            } else {
                EmptyView()
            }
        }
    }
    
    // MARK: - Statistics Preview Card
    
    private var statisticsPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Statistics")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    selectedTab = .statistics
                } label: {
                    Text("View All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 0.96, green: 0.08, blue: 0.42))
                }
            }
            
            // Preview de algunas estadísticas
            VStack(spacing: 12) {
                ForEach(matchStatistics.stats.prefix(3)) { stat in
                    statPreviewRow(stat)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func statPreviewRow(_ stat: Statistic) -> some View {
        HStack(spacing: 8) {
            Text(stat.name)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 100, alignment: .leading)
            
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.purple)
                        .frame(width: geometry.size.width * CGFloat(stat.homePercentage / 100))
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: geometry.size.width * CGFloat(stat.awayPercentage / 100))
                }
            }
            .frame(height: 6)
            .cornerRadius(3)
            
            HStack(spacing: 8) {
                Text(formatValue(stat.homeValue, unit: stat.unit))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, alignment: .trailing)
                
                Text(formatValue(stat.awayValue, unit: stat.unit))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, alignment: .leading)
            }
        }
    }
    
    // MARK: - Highlight Card
    
    @ViewBuilder
    private func highlightCard(_ index: Int) -> some View {
        let minute = index * 10
        HStack(alignment: .top, spacing: 12) {
            // Minute badge
            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(minute)'")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 50)
                
                // Línea vertical
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2)
                    .frame(height: 40)
            }
            
            // Video thumbnail
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 56)
                        .overlay(
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.8))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Highlight \(index)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("\(minute)'")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func formatValue(_ value: Double, unit: String?) -> String {
        if let unit = unit {
            return String(format: "%.1f%@", value, unit)
        } else {
            return "\(Int(value))"
        }
    }
    
    // MARK: - Chat Content View
    
    private var chatContentView: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text(selectedMinute == nil ? "Live Chat" : "Chat at \(selectedMinute!)'")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if selectedMinute == nil {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text("\(chatManager.viewerCount)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Messages filtrados por minuto
                let filteredMessages = chatManager.messages.filter { message in
                    let messageIndex = chatManager.messages.firstIndex(where: { $0.id == message.id }) ?? 0
                    let estimatedMinute = (messageIndex * currentFilterMinute) / max(chatManager.messages.count, 1)
                    return estimatedMinute <= currentFilterMinute
                }
                
                ForEach(filteredMessages) { message in
                    chatMessageRow(message)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(hex: "1B1B25"))
    }
    
    // MARK: - Highlights Content View
    
    private var highlightsContentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(selectedMinute == nil ? "Highlights" : "Highlights at \(selectedMinute!)'")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                // Highlight items basados en eventos del partido (hasta el minuto seleccionado)
                let goalEvents = matchTimeline.events.filter { 
                    if case .goal = $0.type { return $0.minute <= currentFilterMinute }
                    return false
                }
                
                ForEach(Array(goalEvents.enumerated()), id: \.element.id) { index, event in
                    highlightItem(event: event, index: index)
                }
                
                // Highlights adicionales cada 10 minutos (hasta el minuto seleccionado)
                ForEach(Array(stride(from: 10, through: currentFilterMinute, by: 10).enumerated()), id: \.offset) { index, minute in
                    highlightItem(minute: minute, index: index + goalEvents.count)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(hex: "1B1B25"))
    }
    
    private func highlightItem(event: MatchEvent? = nil, minute: Int? = nil, index: Int) -> some View {
        HStack(spacing: 12) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 120, height: 68)
                .overlay(
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.8))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                if let event = event, case .goal = event.type {
                    Text("\(event.player ?? "Goal") - \(event.minute)'")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                } else {
                    Text("Highlight \(index + 1)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text("\(minute ?? event?.minute ?? (index * 5 + 10))'")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Live Scores Content View
    
    private var liveScoresContentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Live Scores")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                
                // Other matches
                ForEach(0..<5) { index in
                    liveScoreItem(index: index)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(hex: "1B1B25"))
    }
    
    private func liveScoreItem(index: Int) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Team A")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("\(index + 1)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    
                    Text("\(index)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Text("Team B")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            
            HStack {
                Text("Premier League")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text("\(45 + index)'")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Polls Content View
    
    private var pollsContentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Polls")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                
                // Active polls
                ForEach(entertainmentManager.activeComponents.filter { $0.type == .poll }) { component in
                    pollCard(component)
                }
                
                // Completed polls
                ForEach(entertainmentManager.completedComponents.filter { $0.type == .poll }) { component in
                    pollCard(component)
                }
                
                // Upcoming polls
                ForEach(entertainmentManager.upcomingComponents.filter { $0.type == .poll }) { component in
                    pollCard(component)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(hex: "1B1B25"))
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 8)
    }
    
    // MARK: - Match Announcement Card
    
    private var matchAnnouncementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                // Viaplay Logo
                ZStack {
                    Circle()
                        .fill(Color.pink)
                        .frame(width: 32, height: 32)
                    
                    Text("V")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("10m")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text("Kampen starter! \(match.homeTeam.name) vs \(match.awayTeam.name)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
            
            // Reactions - Scrollable if needed
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    reactionButton(emoji: "🔥", count: 3456)
                    reactionButton(emoji: "❤️", count: 2345)
                    reactionButton(emoji: "⚽", count: 4567)
                    reactionButton(emoji: "🏆", count: 1234)
                    reactionButton(emoji: "👍", count: 2890)
                    reactionButton(emoji: "👎", count: 123)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.2))
        )
    }
    
    private func reactionButton(emoji: String, count: Int) -> some View {
        Button {
            // Handle reaction
        } label: {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 16))
                
                Text(formatCount(count))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    // MARK: - Chat Message Row
    
    private func chatMessageRow(_ message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            // Avatar
            Circle()
                .fill(message.usernameColor.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(message.username.prefix(1)))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(message.usernameColor)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(message.username)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(message.usernameColor)
                        .lineLimit(1)
                    
                    Text(timeAgo(from: message.timestamp))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                }
                
                Text(message.text)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Poll Card
    
    private func pollCard(_ component: InteractiveComponent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.pink)
                        .frame(width: 32, height: 32)
                    
                    Text("V")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("9m")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("AVSTEMNING")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(component.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
            
            VStack(spacing: 8) {
                ForEach(component.options) { option in
                    Button {
                        handlePollVote(componentId: component.id, optionId: option.id)
                    } label: {
                        HStack {
                            Text(option.text)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            Spacer(minLength: 0)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                    .disabled(entertainmentManager.hasUserResponded(to: component.id))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.2))
        )
    }
    
    // MARK: - Social Media Post
    
    private var socialMediaPostCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                // Profile Picture
                AsyncImage(url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Erling_Haaland_2023.jpg/220px-Erling_Haaland_2023.jpg")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Erling Haaland")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    
                    HStack(spacing: 4) {
                        Text("via X")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("9m")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
            }
            
            Text("Alltid klar for neste mål! ⚽🎯 #ChampionsLeague")
                .font(.system(size: 14))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
            
            // Reactions - Scrollable if needed
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    reactionButton(emoji: "🔥", count: 2345)
                    reactionButton(emoji: "❤️", count: 1876)
                    reactionButton(emoji: "⚽", count: 1234)
                    reactionButton(emoji: "🏆", count: 567)
                    reactionButton(emoji: "👍", count: 890)
                    reactionButton(emoji: "👎", count: 45)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.2))
        )
    }
    
    // MARK: - Helpers
    
    private func handlePollVote(componentId: String, optionId: String) {
        Task {
            do {
                try await entertainmentManager.submitResponse(
                    componentId: componentId,
                    selectedOptions: [optionId]
                )
            } catch {
                print("Error voting: \(error)")
            }
        }
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        }
        return "\(count)"
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        return "\(hours)h"
    }
    
}

// MARK: - Preview

#Preview {
    LiveMatchView(match: Match.barcelonaPSG) {
        print("Dismissed")
    }
    .preferredColorScheme(.dark)
}

