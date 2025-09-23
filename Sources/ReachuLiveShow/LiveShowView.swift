import SwiftUI
import AVKit

public struct LiveShowView: View {
    @StateObject private var viewModel: LiveShowViewModel

    public init(viewModel: LiveShowViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ZStack {
            VideoPlayer(player: viewModel.player)
                .ignoresSafeArea()

            if viewModel.isBuffering {
                ProgressView().progressViewStyle(.circular)
            }

            if let err = viewModel.errorMessage {
                VStack {
                    Text(err).padding(8).background(Color.black.opacity(0.6)).foregroundColor(.white).cornerRadius(8)
                    Button("Reintentar") {
                        Task { await viewModel.refreshStream() }
                    }.buttonStyle(.borderedProminent)
                }
            }
        }
    }
}


