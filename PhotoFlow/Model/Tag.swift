//
//  Tag.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 27.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import RealmSwift

enum TagType: Int {
    case accepted
    case rejected
    case userCreated
}

@objcMembers
class Tag: Object {
    dynamic var name = ""
    dynamic var rawType = TagType.userCreated.rawValue

    override static func primaryKey() -> String? {
        return "name"
    }
}

extension Tag {
    var type: TagType {
        get { return TagType(rawValue: rawType) ?? .userCreated }
        set { rawType = newValue.rawValue }
    }
}

extension Tag {
    static var accepted: Tag {
        let tag = Tag()
        tag.name = "accepted"
        tag.type = .accepted
        return tag
    }

    static var rejected: Tag {
        let tag = Tag()
        tag.name = "rejected"
        tag.type = .rejected
        return tag
    }
}
