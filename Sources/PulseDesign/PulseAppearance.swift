#if canImport(SwiftUI) && canImport(UIKit)
import UIKit

/// UIKit appearance for the pieces SwiftUI cannot style: navigation titles in Syne, a clear bar at the scroll edge.
public enum PulseAppearance {
    @MainActor
    public static func apply() {
        PulseFonts.register()
        let large = UIFont(name: "Syne-ExtraBold", size: 34) ?? .systemFont(ofSize: 34, weight: .heavy)
        let inline = UIFont(name: "Syne-Bold", size: 17) ?? .systemFont(ofSize: 17, weight: .bold)
        let ink = UIColor(red: 0.95, green: 0.96, blue: 0.96, alpha: 1)

        let standard = UINavigationBarAppearance()
        standard.configureWithDefaultBackground()
        standard.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        standard.backgroundColor = UIColor(red: 0.02, green: 0.024, blue: 0.027, alpha: 0.55)
        standard.titleTextAttributes = [.font: inline, .foregroundColor: ink]
        standard.largeTitleTextAttributes = [.font: large, .foregroundColor: ink]

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
