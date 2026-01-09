//
//  VideoTimelineControl.swift
//  Viaplay
//
//  Molecular component: Video timeline control with scrubber
//

import SwiftUI

struct VideoTimelineControl: View {
    let currentMinute: Int
    @Binding var selectedMinute: Int?
    let events: [MatchEvent]
    let isPlaying: Bool
    let totalDuration: Int
    let onPlayPause: () -> Void
    let onFullscreen: () -> Void
    let onSeek: ((Int) -> Void)?  // NEW: Called when user scrubs
    
    init(
        currentMinute: Int,
        selectedMinute: Binding<Int?>,
        events: [MatchEvent],
        isPlaying: Bool = false,
        totalDuration: Int = 90,
        onPlayPause: @escaping () -> Void = {},
        onFullscreen: @escaping () -> Void = {},
        onSeek: ((Int) -> Void)? = nil
    ) {
        self.currentMinute = currentMinute
        self._selectedMinute = selectedMinute
        self.events = events
        self.isPlaying = isPlaying
        self.totalDuration = totalDuration
        self.onPlayPause = onPlayPause
        self.onFullscreen = onFullscreen
        self.onSeek = onSeek
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.2))
            
            VStack(spacing: 12) {
                // Timeline Scrubber
                TimelineScrubber(
                    currentMinute: currentMinute,
                    selectedMinute: $selectedMinute,
                    events: events,
                    totalDuration: totalDuration,
                    onSeek: onSeek
                )
                
                // Controls
                HStack(spacing: 20) {
                    // Time indicator
                    if let selected = selectedMinute {
                        Text("\(selected)'")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    } else {
                        LiveBadge(size: .medium)
                    }
                    
                    Spacer()
                    
                    // Play/Pause
                    Button(action: onPlayPause) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }
                    
                    Spacer()
                    
                    // Fullscreen
                    Button(action: onFullscreen) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
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
}

// MARK: - Timeline Scrubber

struct TimelineScrubber: View {
    let currentMinute: Int
    @Binding var selectedMinute: Int?
    let events: [MatchEvent]
    let totalDuration: Int
    let onSeek: ((Int) -> Void)?
    
    private var displayMinute: Int {
        selectedMinute ?? currentMinute
    }
    
    private var progress: CGFloat {
        CGFloat(displayMinute) / CGFloat(totalDuration)
    }
    
    private func eventMarkerColor(for eventType: MatchEvent.EventType) -> Color {
        switch eventType {
        case .goal: return .green
        case .yellowCard: return .yellow
        case .redCard: return .red
        case .substitution: return .blue
        default: return .white.opacity(0.6)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Progress track
                    Rectangle()
                        .fill(Color(red: 0.96, green: 0.08, blue: 0.42))
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                    
                    // Event markers
                    ForEach(events, id: \.id) { event in
                        let position = CGFloat(event.minute) / CGFloat(totalDuration)
                        Circle()
                            .fill(eventMarkerColor(for: event.type))
                            .frame(width: 8, height: 8)
                            .offset(x: geometry.size.width * position - 4)
                    }
                    
                    // Highlight markers (every 10 minutes)
                    ForEach(Array(stride(from: 10, through: min(currentMinute, totalDuration), by: 10)), id: \.self) { minute in
                        let position = CGFloat(minute) / CGFloat(totalDuration)
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                            .offset(x: geometry.size.width * position - 5)
                    }
                    
                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .offset(x: geometry.size.width * progress - 8)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let percentage = max(0, min(1, value.location.x / geometry.size.width))
                                    let minute = Int(percentage * CGFloat(totalDuration))
                                    selectedMinute = minute
                                    onSeek?(minute)  // Notify ViewModel to update timeline
                                }
                        )
                }
            }
            .frame(height: 20)
            
            // Labels
            HStack {
                Text("0'")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                if selectedMinute == nil {
                    LiveBadge(size: .small)
                } else {
                    Text("\(selectedMinute!)'")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Button {
                        selectedMinute = nil
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
}

#Preview {
    VideoTimelineControl_PreviewWrapper()
}

private struct VideoTimelineControl_PreviewWrapper: View {
    @State var selectedMinute: Int? = nil
    var body: some View {
        VideoTimelineControl(
            currentMinute: 45,
            selectedMinute: $selectedMinute,
            events: [
                MatchEvent(minute: 13, type: .goal, player: "A. Diallo", team: .home, description: nil, score: "1-0"),
                MatchEvent(minute: 18, type: .yellowCard, player: "Casemiro", team: .home, description: nil, score: nil)
            ],
            isPlaying: true
        )
        .background(Color(hex: "1B1B25"))
    }
}


