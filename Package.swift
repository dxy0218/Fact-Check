// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FactCheck",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "FactCheckApp",
            targets: ["FactCheckApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "FactCheckApp",
            path: "Sources/FactCheckApp"
        )
    ]
)
