//
//  Sentry.swift
//  barcelona
//
//  Created by Eric Rabil on 5/6/22.
//

import Foundation
import Sentry

@objc public protocol SentryCommand {
    @objc var name: String { get }
    @objc func execute() throws
}

@objc public protocol SentryCommandGroup {
    @objc var name: String { get }
    @objc var shortDescription: String { get }
    @objc var children: [AnyObject] { get }
}

/** Zero-dependency protocol for bootstrapping Sentry on a Beeper stack */
@objc public protocol IMCSentryConfiguratorProtocol: NSObjectProtocol {
    @objc static var shared: IMCSentryConfiguratorProtocol { get }
    /// Whether the current productName has an assigned DSN.
    @objc var knownProduct: Bool { get }
    /// The hostname you're operating under, default is `UserDefaults.standard.string(forKey: "com.beeper.environment") ?? "beeper.com"`
    @objc var environment: String? { get set }
    /// Default is canary, if you have a release you can set it
    @objc var version: String { get set }
    /// Default is `ProcessInfo.processInfo.processName`, used for release identification and which DSN you use
    @objc var productName: String { get set }
    /// Default is true when running on a debug root
    @objc var debug: Bool { get set }
    /// Convenience function for when you don't need additional sentry configuration
    @objc func startSentry()
    /// Returns the command group for managing the Sentry subsystem
    @objc var commandGroup: SentryCommandGroup { get }
}

/** Resolves the sentry configurator by weak linking against potential paths */
public func IMCSharedSentryConfigurator() -> IMCSentryConfiguratorProtocol? {
    var cls: IMCSentryConfiguratorProtocol? {
        if let cls = NSClassFromString("IMCSentryConfigurator") {
            return unsafeBitCast(cls, to: IMCSentryConfiguratorProtocol.Type.self).shared
        }
        return nil
    }
    let searchPaths = [
        "/Library/Beeper/Frameworks",
        Bundle.main.executableURL!.deletingLastPathComponent().path,
        Bundle.main.executableURL!.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Frameworks").path
    ]
    for searchPath in searchPaths {
        if let _ = dlopen(searchPath + "/CoreSentry.framework/CoreSentry", RTLD_LAZY) {
            return cls
        }
    }
    return nil
}

// This requires linkage against SwiftCLI, you can enable it if that condition is present
#if true
import SwiftCLI

public class SentryCLICommandGroup: CommandGroup {
    public var name: String { group.name }
    public var shortDescription: String { group.shortDescription }
    
    private let group: SentryCommandGroup
    
    public class SentryCLICommand: Command {
        public var name: String { command.name }
        
        private let command: SentryCommand
        
        public init(_ command: SentryCommand) {
            self.command = command
        }
        
        public func execute() throws {
            try command.execute()
        }
    }
    
    public init(_ group: SentryCommandGroup) {
        self.group = group
    }
    
    public private(set) lazy var children: [Routable] = group.children.map { unsafeBitCast($0, to: SentryCommand.self) }.map(SentryCLICommand.init(_:))
}
#endif
