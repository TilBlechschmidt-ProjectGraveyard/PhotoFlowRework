//
//  Asset.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 24.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import CoreServices
import RealmSwift

enum AssetOrigin: Int {
    case files
    case shareExtension
}

@objcMembers
class Asset: Object {
    dynamic var rawIdentifier = ""
    dynamic var rawOrigin = AssetOrigin.files.rawValue

    dynamic var name = ""
    dynamic var uti = ""
    
    dynamic var metadata: Metadata? = nil

    let representations = List<Representation>()
    let tags = List<Tag>()

    override static func primaryKey() -> String? {
        return "rawIdentifier"
    }
}

extension Asset {
    var identifier: UUID {
        get { return UUID(uuidString: rawIdentifier)! }
        set { rawIdentifier = newValue.uuidString }
    }

    var origin: AssetOrigin {
        get { return AssetOrigin(rawValue: rawOrigin) ?? .files }
        set { rawOrigin = newValue.rawValue }
    }
}

extension Asset {
    var fileExtension: String {
        return UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue() as String? ?? ".jpg"
    }
    
    var humanReadableUTI: String? {
        return UTTypeCopyDescription(uti as CFString)?.takeRetainedValue() as String?
    }
    
    var accepted: Bool {
        return tags.filter("rawType = \(TagType.accepted.rawValue)").count == 1
    }

    var rejected: Bool {
        return tags.filter("rawType = \(TagType.rejected.rawValue)").count == 1
    }

    private func removeStatusTags(realm: Realm) throws {
        let newTags = tags.filter { $0.type == .rejected || $0.type == .accepted }

        try realm.write {
            tags.removeAll()
            tags.append(objectsIn: newTags)
        }
    }

    func accept(realm: Realm) throws {
        guard !accepted else {
            try removeStatusTags(realm: realm)
            return
        }

        try removeStatusTags(realm: realm)

        let tag = Tag.accepted
        try realm.write {
            realm.add(tag, update: .modified)
            self.tags.append(tag)
        }
    }

    func reject(realm: Realm) throws {
        guard !rejected else {
            try removeStatusTags(realm: realm)
            return
        }

        try removeStatusTags(realm: realm)

        let tag = Tag.rejected
        try realm.write {
            realm.add(tag, update: .modified)
            self.tags.append(tag)
        }
    }
}
