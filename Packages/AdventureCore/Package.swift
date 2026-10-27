// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AdventureCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "AdventureCore", targets: ["AdventureCore"])],
    targets: [.target(name: "AdventureCore"), .testTarget(name: "AdventureCoreTests", dependencies: ["AdventureCore"])],
    swiftLanguageVersions: [.v5]
)
