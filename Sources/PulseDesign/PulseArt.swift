#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore

/// Remote artwork with a stable gradient placeholder, fade-in, and optional privacy blur.
public struct PulseArt: View {
    @Environment(\.pulseImageBase) private var base
    @Environment(\.pulseBlurArt) private var blur
    let path: String?
    let seed: Int
    var contentMode: ContentMode

    public init(_ path: String?, seed: Int, contentMode: ContentMode = .fill) {
        self.path = path
        self.seed = seed
        self.contentMode = contentMode
    }

    private var url: URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http://") || path.hasPrefix("https://") { return URL(string: path) }
        return base?.appendingAPI(path)
    }

    public var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.4))) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: contentMode)
            default:
                placeholder.overlay { if url != nil && phase.error == nil { Shimmer() } }
            }
        }
        .blur(radius: blur ? 26 : 0)
        .clipped()
    }

    private var placeholder: some View {
        LinearGradient(colors: [.placeholder(seed: seed, shade: 0.06), .placeholder(seed: seed + 5)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay {
                Image(systemName: "play.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.14))
            }
    }
}

private extension AsyncImagePhase {
    var error: Error? { if case .failure(let e) = self { e } else { nil } }
}
#endif
