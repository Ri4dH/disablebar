// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "DisableBar",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "DisableBar", targets: ["DisableBar"])
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
            dependencies: ["TouchBarPrivate"],
            path: "src/DisableBar",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Carbon"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
    ]
)
