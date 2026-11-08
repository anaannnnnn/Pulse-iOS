#if canImport(SwiftUI) && canImport(UIKit)
import UIKit

/// UIKit appearance for navigation bars: clear at the scroll edge, a thin dark blur once content scrolls under it.
public enum PulseAppearance {
    @MainActor
    public static func apply() {
        let ink = UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1)
        let standard = UINavigationBarAppearance()
        standard.configureWithDefaultBackground()
        standard.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        standard.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        standard.titleTextAttributes = [.foregroundColor: ink]
        standard.largeTitleTextAttributes = [.foregroundColor: ink]

        let edge = UINavigationBarAppearance()
        edge.configureWithTransparentBackground()
        edge.titleTextAttributes = standard.titleTextAttributes
        edge.largeTitleTextAttributes = standard.largeTitleTextAttributes

        let bar = UINavigationBar.appearance()
        bar.standardAppearance = standard
        bar.compactAppearance = standard
        bar.scrollEdgeAppearance = edge
    }
}
#endif
