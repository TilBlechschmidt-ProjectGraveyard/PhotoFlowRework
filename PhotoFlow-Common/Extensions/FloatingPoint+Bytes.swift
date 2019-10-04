//
//  FloatingPoint+Bytes.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 04.10.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation

func convertToBytes<T>(_ value: T, withCapacity capacity: Int) -> [UInt8] {
    var mutableValue = value
    
    return withUnsafePointer(to: &mutableValue) {
        return $0.withMemoryRebound(to: UInt8.self, capacity: capacity) {
            return Array(UnsafeBufferPointer(start: $0, count: capacity))
        }
    }
}

extension FloatingPoint {
    var bytes: [UInt8] { return convertToBytes(self, withCapacity: MemoryLayout<Self>.size) }
    
    init?(bytes: [UInt8]) {
        guard bytes.count == MemoryLayout<Self>.size else { return nil }
        
        self = bytes.withUnsafeBytes {
            return $0.load(as: Self.self)
        }
    }
}
