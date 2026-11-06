// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Pulse",
    defaultLocalization: "en",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "PulseCore", targets: ["PulseCore"]),
        .library(name: "PulseDesign", targets: ["PulseDesign"]),
        .library(name: "PulseFeatures", targets: ["PulseFeatures"]),
        .library(name: "PulseApp", targets: ["PulseApp"]),
    ],
    targets: [
        // Networking, models, session logic. Pure Foundation: builds and tests on Linux CI too.
        .target(name: "PulseCore"),
        // Graphite Glass design system: tokens, glass surfaces, motion, reusable components.
        .target(
            name: "PulseDesign",
            dependencies: ["PulseCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // Screens and view models.
        .target(
            name: "PulseFeatures",
            dependencies: ["PulseCore", "PulseDesign"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // Root scene. The Xcode app shell in App/ only calls PulseRootScene().
        .target(
            name: "PulseApp",
            dependencies: ["PulseCore", "PulseDesign", "PulseFeatures"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(name: "PulseCoreTests", dependencies: ["PulseCore"]),
    ]
)
