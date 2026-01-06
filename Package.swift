// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "vigil",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "vigil",
            dependencies: [],
            path: "vigil",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ],
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("IOKit"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("DiskArbitration"),
            ]
        ),
    ]
)
