#if canImport(SwiftUI) && canImport(UIKit)
import CoreText
import Foundation

/// Registers the bundled fonts (Syne, DM Serif Display) once per process.
public enum PulseFonts {
    private static let once: Void = {
        let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? []
        guard !urls.isEmpty else { return }
        CTFontManagerRegisterFontsForURLs(urls as CFArray, .process, nil)
    }()

    public static func register() { _ = once }
}
#endif
