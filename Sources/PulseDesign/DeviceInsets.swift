#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import UIKit

/// Safe-area values for screens that draw edge to edge (Home hero). Reads the live window, so it is right on every device,
/// from the iPhone SE (20pt) to Dynamic Island phones (59pt) and iPad.
public enum DeviceInsets {
    @MainActor
    public static var top: CGFloat {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.first(where: { $0.activationState == .foregroundActive })?.keyWindow ?? scenes.first?.keyWindow
        return max(window?.safeAreaInsets.top ?? 0, 20)
    }
}
#endif
