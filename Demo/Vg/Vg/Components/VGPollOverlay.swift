import SwiftUI

struct VGPollOverlay: View {
    let poll: PollEventData
    let isChatExpanded: Bool
    let onVote: (String) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedOption: String?
    @State private var hasVoted = false
    @State private var showResults = false
    @State private var dragOffset: CGFloat = 0
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var isLandscape: Bool { verticalSizeClass == .compact }
    
    private var bottomPadding: CGFloat {
        if isLandscape { return isChatExpanded ? 250 : 156 }
        return isChatExpanded ? 250 : 80
    }
    
    var body: some View {
        VStack {
            Spacer()
            content
                .padding(.horizontal, 16)
                .padding(.bottom, bottomPadding)
                .offset(y: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in if value.translation.height > 0 { dragOffset = value.translation.height } }
                        .onEnded { value in
                            if value.translation.height > 100 { onDismiss() } else { withAnimation(.spring()) { dragOffset = 0 } }
                        }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    private var content: some View {
        ZStack {
            if !showResults { pollFrontView } else { pollResultsView }
        }
        .rotation3DEffect(.degrees(showResults ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
    }
    
    private var pollFrontView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(poll.question)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    Text("\(poll.duration)s")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(14)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(poll.options, id: \.text) { option in
                    Button(action: {
                        selectedOption = option.text
                        hasVoted = true
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showResults = true }
                        onVote(option.text)
                    }) {
                        HStack(spacing: 12) {
                            if let avatar = option.avatarUrl, let url = URL(string: avatar) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image): image.resizable().aspectRatio(contentMode: .fill)
                                    case .empty: Color.white.opacity(0.1)
                                    case .failure: Color.white.opacity(0.1)
                                    @unknown default: Color.white.opacity(0.1)
                                    }
                                }
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
                            }
                            Text(option.text)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            if selectedOption == option.text {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(VGTheme.Colors.red)
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.12)))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(VGTheme.Colors.red.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 12, x: 0, y: 6)
        )
    }
    
    private var pollResultsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Resultater")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(14)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(poll.options, id: \.text) { option in
                    resultBar(for: option)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(VGTheme.Colors.red.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 12, x: 0, y: 6)
        )
    }
    
    private func resultBar(for option: PollOption) -> some View {
        let percent = CGFloat.random(in: 10...70)
        return HStack {
            Text(option.text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            Text("\(Int(percent))%")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(12)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08))
                RoundedRectangle(cornerRadius: 10).fill(VGTheme.Colors.red.opacity(0.32)).frame(maxWidth: .infinity, alignment: .leading).overlay(GeometryReader { proxy in
                    Rectangle().fill(VGTheme.Colors.red).frame(width: proxy.size.width * (percent / 100), height: proxy.size.height).cornerRadius(10)
                })
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


