//
//  Representation.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 24.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import RealmSwift

enum RepresentationType: Int {
    case original
    case thumbnail
}

@objcMembers
class Representation: Object {
    /// SHA256 hash (hex representation)
    /// Used as filename and primary key
    dynamic var identifier = ""
    
    dynamic var rawType = RepresentationType.original.rawValue

    override static func primaryKey() -> String? {
        return "identifier"
    }
}

extension Representation {
    var type: RepresentationType {
        get { return RepresentationType(rawValue: rawType) ?? .original }
        set { rawType = newValue.rawValue }
    }
}
