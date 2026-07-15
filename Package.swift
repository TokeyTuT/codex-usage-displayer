// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "CodexUsage",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "CodexUsage", targets: ["CodexUsage"])
  ],
  targets: [
    .executableTarget(
      name: "CodexUsage",
      path: "Sources/CodexUsage"
    ),
    .testTarget(
      name: "CodexUsageTests",
      dependencies: ["CodexUsage"],
      path: "Tests/CodexUsageTests"
    ),
  ],
  swiftLanguageModes: [.v5]
)
