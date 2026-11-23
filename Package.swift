// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "DisableBar",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "DisableBar", targets: ["DisableBar"])
    ],
    dependencies: [
        // Auto-updates for the direct-download build.
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.10.0"),
    ],
    targets: [
        // Thin Objective-C shim around the private AppKit / DFRFoundation
        // calls used to present a full-width "system modal" Touch Bar.
        .target(
            name: "TouchBarPrivate",
            path: "src/TouchBarPrivate",
            linkerSettings: [.linkedFramework("AppKit")]
        ),
        .executableTarget(
            name: "DisableBar",
            dependencies: [
                "TouchBarPrivate",
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "src/DisableBar",
            linkerSettings: [
                // Sparkle.framework is embedded in DisableBar.app/Contents/Frameworks.
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"]),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Carbon"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
    ]
)
