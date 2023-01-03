import Foundation
import Socket
import Swog

fileprivate let log = Logger(category: "UnixSocketMautrixIPCChannel")

public class UnixSocketMautrixIPCChannel: MautrixIPCInputChannel, MautrixIPCOutputChannel {
    private let socket: Socket
    private var readThread: Thread? = nil
    private var readRunLoop: CFRunLoop? = nil
    private var readCallback: ((Data) -> ())? = nil
    
    public init(_ socketPath: String) {
        do {
            try socket = Socket.create(family:.unix)
            try socket.connect(to: socketPath)
            log.info("Connected to unix socket \(socketPath)")
        } catch let error {
            fatalError("Failed to connect unix socket \(error)")
        }
    }
    
    private func setupReadThread() {
        readThread = Thread {
            self.readRunLoop = CFRunLoopGetCurrent()
            
            RunLoop.current.schedule {
                do {
                    var shouldKeepRunning = true
                    
                    repeat {
                        log.info("Waiting for data")
                        var readData = Data(capacity: 4096)
                        let bytesRead = try self.socket.read(into: &readData)
                        log.info("Read \(bytesRead) bytes from the unix socket")
                        
                        if bytesRead > 0 {
                            if let readCallback = self.readCallback {
                                readCallback(readData)
                            }
                        }
                        
                        if bytesRead == 0 {
                            shouldKeepRunning = false
                            break
                        }
                    } while shouldKeepRunning
                } catch let error {
                    log.error("Failed to read payload from unix socket: \(String(describing: error))")
                }
            }
            
            RunLoop.current.run()
        }
    }
    
    func performOnThread(_ callback: @escaping () -> ()) {
        guard let runLoop = readRunLoop else {
            // Thread not yet started, just call it immediately
            callback()
            return
        }
        CFRunLoopPerformBlock(runLoop, CFRunLoopMode.commonModes.rawValue, callback)
        CFRunLoopWakeUp(runLoop)
    }
    
    public func listen(_ cb: @escaping (Data) -> ()) {
        self.readCallback = cb
        if readThread == nil {
            setupReadThread()
        }
        readThread!.start()
    }
    
    public func write(_ data: Data) {
        do {
            log.info("Writing \(data.count) bytes to the unix socket")
            try socket.write(from: data)
        } catch let error {
            log.error("Failed to write payload to unix socket: \(String(describing: error))")
        }
    }
}
