#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// Violet scrubber with buffer track, grow-on-touch knob and a time bubble.
struct Scrubber: View {
    let current: Double
    let duration: Double
    let buffered: Double
    var onScrubStart: () -> Void
    var onScrub: (Double) -> Void
    var onScrubEnd: (Double) -> Void

    @State private var dragFraction: Double?

    private var fraction: Double {
        if let dragFraction { return dragFraction }
        return duration > 0 ? min(max(current / duration, 0), 1) : 0
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let active = dragFraction != nil
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.2)).frame(height: active ? 10 : 6)
                Capsule().fill(.white.opacity(0.28))
                    .frame(width: width * (duration > 0 ? min(buffered / duration, 1) : 0), height: active ? 10 : 6)
                Capsule().fill(Theme.gradient).frame(width: max(width * fraction, 0), height: active ? 10 : 6)
                Circle().fill(.white)
                    .frame(width: active ? 22 : 14, height: active ? 22 : 14)
                    .shadow(color: Theme.accent.opacity(0.6), radius: active ? 10 : 4)
                    .offset(x: width * fraction - (active ? 11 : 7))
                if active {
                    Text(Format.clock(fraction * duration))
                        .font(PulseFont.timecode(.caption)).foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .pulseCapsuleGlass()
                        .offset(x: min(max(width * fraction - 28, 0), width - 56), y: -34)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if dragFraction == nil { onScrubStart() }
                        let f = min(max(value.location.x / max(width, 1), 0), 1)
                        dragFraction = f
                        onScrub(f * duration)
                    }
                    .onEnded { value in
                        let f = min(max(value.location.x / max(width, 1), 0), 1)
                        dragFraction = nil
                        onScrubEnd(f * duration)
                    }
            )
            .animation(.snappy(duration: 0.18), value: active)
        }
        .frame(height: 44)
        .accessibilityElement()
        .accessibilityLabel("Playback position")
        .accessibilityValue("\(Format.clock(current)) of \(Format.clock(duration))")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onScrubEnd(min(current + 10, duration))
            case .decrement: onScrubEnd(max(current - 10, 0))
            @unknown default: break
            }
        }
    }
}
#endif
