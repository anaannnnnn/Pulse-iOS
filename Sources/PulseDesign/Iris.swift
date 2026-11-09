#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

/// Black cover with a circular aperture. `closed == true` shrinks the aperture to nothing, like a projector iris closing.
public struct IrisOverlay: View {
    let closed: Bool

    public init(closed: Bool) { self.closed = closed }

    public var body: some View {
        GeometryReader { proxy in
            let diameter = hypot(proxy.size.width, proxy.size.height) * 1.15
            Rectangle()
                .fill(.black)
                .mask {
                    Rectangle()
                        .overlay {
                            Circle()
                                .frame(width: closed ? 1 : diameter, height: closed ? 1 : diameter)
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                }
                .animation(.easeInOut(duration: 0.43), value: closed)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
#endif
