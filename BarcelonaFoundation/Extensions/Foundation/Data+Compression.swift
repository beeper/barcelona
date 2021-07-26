//
//  Data+Compression.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Compression

public extension Data {
    /**
     Returns a compressed version of the data using the ZLIB compression format
     */
    var compressed: Data? {
        // MARK: - Allocation
        let inputDataSize = self.count
        let byteSize = MemoryLayout<UInt8>.stride
        let bufferSize = inputDataSize / byteSize
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        var sourceBuffer = Array<UInt8>(repeating: 0, count: bufferSize)
        
        // MARK: - Compression
        self.copyBytes(to: &sourceBuffer, count: inputDataSize)
        let compressedSize = compression_encode_buffer(destinationBuffer, inputDataSize, &sourceBuffer, inputDataSize, nil, COMPRESSION_ZLIB)
        guard compressedSize != 0 else { return nil }
        
        // MARK: - Resolution
        let encodedData: Data = NSData(bytesNoCopy: destinationBuffer, length: compressedSize) as Data
        
        return encodedData
    }
}
