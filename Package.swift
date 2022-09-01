// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

extension Target.Dependency {
    static func paris(_ name: String) -> Target.Dependency {
        .product(name: name, package: "Paris")
    }
}

extension Package {
    func addingLibrary(name: String, dependencies: [Target.Dependency] = []) -> Package {
        products.append(.library(name: name, targets: [name]))
        targets.append(.target(name: name, dependencies: dependencies))
        return self
    }
}

extension Array {
    static func paris(_ names: String...) -> [Target.Dependency] {
        names.map { .paris($0) }
    }
}

let package = Package(
    name: "Barcelona",
    platforms: [
        .iOS(.v13), .macOS(.v10_15)
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/open-imcore/BarcelonaFoundation", from: "1.0.2"),
        .package(name: "GRDB", url: "https://github.com/groue/GRDB.swift.git", .upToNextMajor(from: "5.26.0")),
        .package(url: "https://github.com/EricRabil/Paris", .revisionItem("0f631b35a2a8871b8517dda33973a76cfacaea33")),
        .package(name: "FeatureFlags", url: "https://github.com/EricRabil/FeatureFlags.swift", from: "1.0.0"),
        .package(url: "https://github.com/sendyhalim/Swime", .upToNextMajor(from: "3.0.7")),
        .package(url: "https://github.com/steipete/InterposeKit", .branchItem("master")),
        .package(url: "https://github.com/jakeheis/SwiftCLI", .upToNextMajor(from: "6.0.3")),
        .package(name: "Sentry", url: "https://github.com/getsentry/sentry-cocoa", .upToNextMajor(from: "7.15.0")),
        .package(url: "https://github.com/Flight-School/AnyCodable", .upToNextMajor(from: "0.6.1")),
        .package(name: "Gzip", url: "https://github.com/1024jp/GzipSwift", .upToNextMajor(from: "5.1.1")),
        .package(url: "https://github.com/EricRabil/SwiftyJavaScriptCore", .upToNextMajor(from: "1.0.2")),
        .package(url: "https://github.com/open-imcore/BarcelonaIPC", from: "1.0.5")
    ]
).addingLibrary(name: "BarcelonaDB", dependencies: ["GRDB", "BarcelonaFoundation"])
.addingLibrary(name: "CBarcelona", dependencies: [.paris("CommunicationsFilter"), .paris("IMCore")])
.addingLibrary(name: "Barcelona", dependencies: [
    "CBarcelona", "BarcelonaDB", "FeatureFlags", "Swime", "InterposeKit", "SwiftCLI", "Sentry", "AnyCodable", "Gzip", "BarcelonaFoundation"
] + .paris("DataDetectorsCore", "IMDPersistence", "IMDaemonCore", "IMCore", "IMSharedUtilities", "IMFoundation", "IDS", "DigitalTouchShared", "LinkPresentation"))
.addingLibrary(name: "BarcelonaJS", dependencies: ["Barcelona", "SwiftyJavaScriptCore", "BarcelonaIPC"])
//.addingLibrary(name: "BarcelonaMautrixIPC", dependencies: [
//    "Barcelona", "BarcelonaDB", "SwiftyContacts", "ERBufferedStream", "Pwomise"
//])
