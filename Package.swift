// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "GitBoy", platforms: [.macOS(.v14)], products: [.executable(name: "GitBoy", targets: ["GitBoy"])], targets: [.executableTarget(name: "GitBoy")], swiftLanguageModes: [.v5])
