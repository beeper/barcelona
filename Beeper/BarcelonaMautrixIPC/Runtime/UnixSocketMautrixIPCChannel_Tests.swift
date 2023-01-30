//
//  UnixSocketMautrixIPCChannel_Tests.swift
//  BarcelonaMautrixIPCTests
//
//  Created by Joonas Myhrberg on 29.1.2023.
//

import NIO
import NIOFoundationCompat
import XCTest

@testable import BarcelonaMautrixIPC

final class UnixSocketMautrixIPCChannel_Tests: XCTestCase {

    /// Default buffer is 2048, write more than that to test multiple calls to read/write.
    private let numberOfTestBytes = 3000

    func testRead() throws {
        let testSocketPath = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString).path()

        let randomBytes = (0..<numberOfTestBytes).map { _ in UInt8.random(in: 0...UInt8.max) }
        let wantData = Data(randomBytes)

        let expectation = expectation(description: "client received bytes")

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let server = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.addHandler(TestWriter(data: wantData))
            }
        let testServerChannel = try server.bind(unixDomainSocketPath: testSocketPath).wait()

        let ipcChannel = UnixSocketMautrixIPCChannel(testSocketPath)

        var receivedData = Data()
        ipcChannel.listen { data in
            receivedData.append(data)
            if receivedData.count == wantData.count {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 1)

        XCTAssertEqual(receivedData, wantData)

        try testServerChannel.close().wait()
        try testServerChannel.closeFuture.wait()
    }

    func testWrite() throws {
        let testSocketPath = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString).path()

        let randomBytes = (0..<numberOfTestBytes).map { _ in UInt8.random(in: 0...UInt8.max) }
        let randomData = Data(randomBytes)

        let expectation = expectation(description: "server received bytes")

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let server = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.addHandler(ReceiveTester(wantData: randomData, expectation: expectation))
            }
        let testServerChannel = try server.bind(unixDomainSocketPath: testSocketPath).wait()

        let ipcChannel = UnixSocketMautrixIPCChannel(testSocketPath)

        ipcChannel.write(randomData)

        waitForExpectations(timeout: 1)

        try testServerChannel.close().wait()
        try testServerChannel.closeFuture.wait()
    }
}

private class TestWriter: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer

    private let data: Data

    init(data: Data) {
        self.data = data
    }

    func channelActive(context: ChannelHandlerContext) {
        let bytes = context.channel.allocator.buffer(data: data)
        context.writeAndFlush(NIOAny(bytes), promise: nil)
    }
}

private class ReceiveTester: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer

    private let wantData: Data
    private let expectation: XCTestExpectation

    private var receivedBytes = [UInt8]()
    private var received = Data()

    init(wantData: Data, expectation: XCTestExpectation) {
        self.wantData = wantData
        self.expectation = expectation
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let bytes = unwrapInboundIn(data)
        received.append(contentsOf: bytes.readableBytesView)

        if received.count == wantData.count {
            XCTAssertEqual(received, wantData)
            expectation.fulfill()
        }
    }
}
