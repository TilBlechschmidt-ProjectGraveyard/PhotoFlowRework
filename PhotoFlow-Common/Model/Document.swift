//
//  Document.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 23.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import RealmSwift

enum DocumentError: Error {
    case invalidFile
    case documentNotOpen
    case urlMismatch
}

class Document: UIDocument {
    internal struct Filenames {
        internal static let identifier = "project.identifier"
        internal static let realm = "database.realm"
    }

    lazy var representationManager = RepresentationManager(document: self)
    lazy var assetManager = AssetManager(document: self)

    private(set) var identifier = UUID()

    private func readIdentifier(from url: URL) throws -> UUID {
        let identifierLocation = url.appendingPathComponent(Document.Filenames.identifier)
        let identifierString = try String(contentsOf: identifierLocation, encoding: .utf8)
        guard let identifier = UUID(uuidString: identifierString) else {
            throw DocumentError.invalidFile
        }

        return identifier
    }
}

// MARK: UIDocument overrides
extension Document {
    override func read(from url: URL) throws {
        identifier = try readIdentifier(from: url)
    }

    override func writeContents(_ contents: Any, to url: URL, for saveOperation: UIDocument.SaveOperation, originalContentsURL: URL?) throws {
        // Make sure the document bundle exists
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])

        // Write the identifier
        let identifier = self.identifier
        let identifierLocation = url.appendingPathComponent(Document.Filenames.identifier)
        try identifier.uuidString.data(using: .utf8)!.write(to: identifierLocation)

        if let originalContentsURL = originalContentsURL, FileManager.default.fileExists(atPath: originalContentsURL.path) {
            // Store a copy of the realm database at the new location
            let realmURL = originalContentsURL.appendingPathComponent(Document.Filenames.realm)
            let realm = try createRealm(url: realmURL)
            try realm.writeCopy(toFile: url.appendingPathComponent(Document.Filenames.realm))

            // Copy over the images (or move?)
            try FileManager.default.copyItem(
                at: originalContentsURL.appendingPathComponent(Document.Filenames.imageStorage),
                to: url.appendingPathComponent(Document.Filenames.imageStorage))
        } else {
            // Create a new instance of the realm database
            let realmURL = url.appendingPathComponent(Document.Filenames.realm)
            _ = try createRealm(url: realmURL)
        }
    }

    override func handleError(_ error: Error, userInteractionPermitted: Bool) {
        super.handleError(error, userInteractionPermitted: userInteractionPermitted)
        print(error)
        return
    }
}


// MARK: Realm storage functions
extension Document {
    func createRealm(url: URL? = nil) throws -> Realm {
        let url = url ?? fileURL.appendingPathComponent(Document.Filenames.realm)
        let configuration = Realm.Configuration(fileURL: url, objectTypes: [Tag.self, Asset.self, Representation.self])
        return try Realm(configuration: configuration)
    }
}

// MARK: Convenience declarations
extension Document {
    var title: String {
        return fileURL.deletingPathExtension().lastPathComponent
    }
}
