// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NonSleep",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "nonsleep", targets: ["nonsleep"]),
    ],
    targets: [
        .target(
            name: "NonSleepKit",
            linkerSettings: [
                .linkedFramework("IOKit", .when(platforms: [.macOS])),
                .linkedFramework("CoreGraphics", .when(platforms: [.macOS])),
            ]
        ),
        .executableTarget(name: "nonsleep", dependencies: ["NonSleepKit"]),
        .testTarget(name: "NonSleepKitTests", dependencies: ["NonSleepKit"]),
    ]
)

// The menu bar app is AppKit/SwiftUI; Linux gets the CLI only.
#if os(macOS)
package.products.append(.executable(name: "NonSleepBar", targets: ["NonSleepBar"]))
package.targets.append(.executableTarget(name: "NonSleepBar", dependencies: ["NonSleepKit"]))
#endif
