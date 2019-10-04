//
//  TIFFMetadata.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 21.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import RealmSwift

@objcMembers
class TIFFMetadata: Object {
    // Other fields: Compression, DateTime, Orientation
    dynamic var copyright: String? = nil

    dynamic var make: String? = nil
    dynamic var model: String? = nil

    dynamic var firmwareVersion: String? = nil
}

extension TIFFMetadata {
    convenience init(from dict: [String: Any]) {
        self.init()
        
        copyright = dict.take(from: "Copyright")

        make = dict.take(from: "Make")
        model = dict.take(from: "Model")

        firmwareVersion = dict.take(from: "Software")
    }
}
