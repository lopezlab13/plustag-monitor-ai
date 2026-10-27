// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "PlustagMonitor", platforms: [.macOS(.v13)], products: [.executable(name: "PlustagMonitor", targets: ["PlustagMonitor"])], targets: [.executableTarget(name: "PlustagMonitor", resources: [.copy("Assets")]), .testTarget(name: "PlustagMonitorTests", dependencies: ["PlustagMonitor"])])
