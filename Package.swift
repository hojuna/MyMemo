// swift-tools-version: 6.0
import PackageDescription

let testFrameworkPath = "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"

let package = Package(
    name: "MyMemo",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(
            name: "MyMemoCore",
            path: "Sources/Core"
        ),
        .executableTarget(
            name: "MyMemo",
            dependencies: ["MyMemoCore"],
            path: "Sources/App"
        ),
        // CLI-runnable verification of core logic. SwiftPM cannot host .xctest
        // bundles on a Command-Line-Tools-only machine (no `xctest` host tool),
        // so this executable provides real, runnable checks. The swift-testing
        // suite in Tests/ remains for Xcode/CI environments.
        .executableTarget(
            name: "MyMemoCheck",
            dependencies: ["MyMemoCore"],
            path: "Sources/Check"
        ),
        .testTarget(
            name: "MyMemoCoreTests",
            dependencies: ["MyMemoCore"],
            path: "Tests",
            swiftSettings: [
                .unsafeFlags(["-F", testFrameworkPath]),
                // _Testing_Foundation cross-import overlay ships no swiftmodule on
                // Command Line Tools, so disable auto-loading it.
                .unsafeFlags(["-Xfrontend", "-disable-cross-import-overlays"])
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-F", testFrameworkPath,
                    "-framework", "Testing",
                    "-Xlinker", "-rpath", "-Xlinker", testFrameworkPath
                ])
            ]
        )
    ]
)
