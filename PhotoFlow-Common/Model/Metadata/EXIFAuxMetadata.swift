//
//  EXIFAuxMetadata.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 21.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import RealmSwift

@objcMembers
class EXIFAuxMetadata: Object {
    dynamic var lensModel: String?
    dynamic var lensSerialNumber: String?

    dynamic var stabilized: Bool = false
}

extension EXIFAuxMetadata {
    convenience init(from dict: [String: Any]) {
        self.init()
        
        // TODO LensModel is sometimes in {Exif} instead of {ExifAux}
        lensModel = dict.take(from: "LensModel")
        lensSerialNumber = dict.take(from: "LensSerialNumber")
        stabilized = dict.take(from: "ImageStabilization") ?? false
    }
}
