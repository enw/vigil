// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "vigil",
    platforms: [
        .macOS(.v11)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "vigil",
            dependencies: [],
            path: "my-istat",
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("IOKit"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("DiskArbitration"),
            ]
        ),
    ]
)
