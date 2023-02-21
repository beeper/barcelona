import Foundation
import NIO
import NIOFoundationCompat
import Logging

/// Handles sending and receiving data from the Mautrix UNIX socket.
public class UnixSocketMautrixIPCChannel: MautrixIPCInputChannel, MautrixIPCOutputChannel {

    // MARK: - Properties

    private var channel: Channel?
    private let socketPath: String

    private let log = Logger(label: "UnixSocketMautrixIPCChannel")

    // MARK: - Initializers

    public init(_ socketPath: String) {
        self.socketPath = socketPath
    }

    // MARK: - Methods

    public func listen(_ cb: @escaping (Data) -> Void) {
        do {
            let group = MultiThreadedEventLoopGroup(numberOfThreads: 2)
            let client = ClientBootstrap(group: group)
            channel = try client.channelInitializer { channel in
                channel.pipeline.addHandler(ClosureReadHandler(readCallback: cb))
            }
            .connect(unixDomainSocketPath: socketPath)
            .wait()
        } catch {
            log.error("Failed to start listening to unix socket: \(error.localizedDescription)")
        }
    }

    public func write(_ data: Data) {
        do {
            let bytes = ByteBuffer(bytes: data)
            try channel?.writeAndFlush(bytes).wait()
        } catch {
            log.error("Failed to write payload to unix socket: \(error.localizedDescription)")
        }
    }
}

/// Calls the given closure when receiving data from the channel.
private class ClosureReadHandler: ChannelInboundHandler {

    // MARK: - Types

    typealias InboundIn = ByteBuffer

    // MARK: - Properties

    private let readCallback: (Data) -> Void

    // MARK: - Initializers

    /// Create a handler with a read callback.
    /// - Parameter readCallback: Closure to call when data is available.
    init(readCallback: @escaping (Data) -> Void) {
        self.readCallback = readCallback
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var bytes = unwrapInboundIn(data)
        guard let data = bytes.readData(length: bytes.readableBytes) else {
            return
        }
        readCallback(data)
    }
}
