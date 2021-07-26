import Foundation
import os.log
import _SwiftOSOverlayShims

private extension StaticString {
    func withOSLogStr(_ cb: (UnsafePointer<CChar>) -> ()) {
        withUTF8Buffer { (buf: UnsafeBufferPointer<UInt8>) in
            buf.baseAddress!.withMemoryRebound(to: CChar.self, capacity: buf.count) { str in
                cb(str)
            }
        }
    }
}

private class OSLogExtensionData {
    private static var data = [OSLog: OSLogExtensionData]()
    
    @inline(__always)
    static func data(forLog log: OSLog) -> OSLogExtensionData {
        if let data = data[log] {
            return data
        }
        
        data[log] = OSLogExtensionData()
        
        return data(forLog: log)
    }
    
    var enabled: Bool = true
    var rerouteToStandardOutput = false
}

public extension OSLog {
    private var data: OSLogExtensionData { OSLogExtensionData.data(forLog: self) }
    
    var enabled: Bool {
        get { data.enabled }
        set { data.enabled = newValue }
    }
    
    var rerouteToStandardOutput: Bool {
        get { data.rerouteToStandardOutput }
        set { data.rerouteToStandardOutput = newValue }
    }
    
    func log(_ message: StaticString, dso: UnsafeRawPointer = #dsohandle, type: OSLogType, _ args: [CVarArg]) {
        guard enabled else {
            return
        }
        
        let ra = _swift_os_log_return_address()
        
        if _slowPath(rerouteToStandardOutput) {
            // if debug build, print OSLog out to std for easy debugging. console ugly for debug. ratchet.
            print(String(format: message.description, arguments: args))
            return
        }
        
        message.withOSLogStr { str in
            withVaList(args) { valist in
                _swift_os_log(dso, ra, self, type, str, valist)
            }
        }
    }
    
    func signpost(_ type: OSSignpostType, dso: UnsafeRawPointer = #dsohandle, _ name: StaticString, _ message: StaticString? = nil, _ args: [CVarArg] = [], id: OSSignpostID) {
        let ra = _swift_os_log_return_address()
        
        name.withOSLogStr { name in
            guard let message = message else {
                _swift_os_signpost(dso, ra, self, type, name, id.rawValue)
                return
            }
            
            message.withOSLogStr { message in
                withVaList(args) { valist in
                    _swift_os_signpost_with_format(dso, ra, self, type, name, id.rawValue, message, valist)
                }
            }
        }
    }
    
    func signpost(dso: UnsafeRawPointer = #dsohandle, _ name: StaticString, _ message: StaticString? = nil, _ args: [CVarArg]) -> () -> () {
        let id = OSSignpostID(log: self)
        
        signpost(.begin, dso: dso, name, message, args, id: id)
        
        return {
            self.signpost(.end, dso: dso, name, id: id)
        }
    }
    
    func signpost(dso: UnsafeRawPointer = #dsohandle, _ name: StaticString, _ message: StaticString? = nil, _ args: CVarArg...) -> () -> () {
        let id = OSSignpostID(log: self)
        
        signpost(.begin, dso: dso, name, message, args, id: id)
        
        return {
            self.signpost(.end, dso: dso, name, id: id)
        }
    }
    
    @inline(__always)
    func info(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .info, args)
    }
    
    @inline(__always)
    func error(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .error, args)
    }
    
    @inline(__always)
    func fault(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .fault, args)
    }
    
    @inline(__always)
    func debug(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .debug, args)
    }
    
    @inline(__always)
    func callAsFunction(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .default, args)
    }
}
