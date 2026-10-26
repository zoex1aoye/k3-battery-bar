// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "K3BatteryBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "K3BatteryBar", targets: ["K3BatteryBar"]),
        .executable(name: "k3-battery", targets: ["K3BatteryCLI"])
    ],
    targets: [
        .target(
            name: "K3BatteryCore",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ],
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        ),
        .executableTarget(
            name: "K3BatteryBar",
            dependencies: ["K3BatteryCore"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreText"),
                .linkedFramework("IOKit")
            ]
        ),
        .executableTarget(
            name: "K3BatteryCLI",
            dependencies: ["K3BatteryCore"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "K3BatteryCoreTests",
            dependencies: ["K3BatteryCore"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
