//
//  Data+SHA256.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 24.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import CommonCrypto

extension Data {
    func sha256() -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

       _ = self.withUnsafeBytes {
           CC_SHA256($0.baseAddress, UInt32(self.count), &digest)
       }

        return Data(digest)
    }

    func sha256String() -> String {
        return sha256().reduce(into: "", { $0 += String(format:"%02x", $1) })
    }
}
