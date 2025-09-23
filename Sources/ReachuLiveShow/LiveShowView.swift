import SwiftUI
import AVKit
import WebKit

public struct LiveShowView: View {
    @StateObject private var viewModel: LiveShowViewModel

    public init(viewModel: LiveShowViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ZStack {
            Group {
                if let webURL = viewModel.webURL {
                    WebPlayerView(url: webURL)
                } else {
                    VideoPlayer(player: viewModel.player)
                }
            }
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

private struct WebPlayerView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let web = WKWebView(frame: .zero, configuration: config)
        web.scrollView.isScrollEnabled = false
        web.isOpaque = false
        web.backgroundColor = .black
        return web
    }
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}


