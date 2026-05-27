// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Pill",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Pill", targets: ["Pill"])
    ],
    targets: [
        .executableTarget(
            name: "Pill",
            path: "Sources/DynamicNotch",
            exclude: ["Bridge"]
        )
    ]
)