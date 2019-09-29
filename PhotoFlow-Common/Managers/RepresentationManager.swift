//
//  RepresentationManager.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 24.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import UIKit

class RepresentationData {
    let data: Data
    let image: UIImage?

    init(_ data: Data) {
        self.data = data
        image = UIImage(data: data)
    }

    func image(scaledBy scale: Double) -> UIImage? {
        guard let ciImage = CIImage(data: data) else { return nil }
        let scaled = CIImage.scaleFilter(ciImage, aspectRatio: 1, scale: scale)
        return UIImage(ciImage: scaled)
    }
}

extension CIImage {
    static func scaleFilter(_ input:CIImage, aspectRatio : Double, scale : Double) -> CIImage {
        let scaleFilter = CIFilter(name:"CILanczosScaleTransform")!
        scaleFilter.setValue(input, forKey: kCIInputImageKey)
        scaleFilter.setValue(scale, forKey: kCIInputScaleKey)
        scaleFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
        return scaleFilter.outputImage!
    }
}

struct CachedRepresentationData {
    weak var representationData: RepresentationData?
}

enum RepresentationManagerError: Error {
    case representationExists
}

class RepresentationManager {
    private var cache: [String: CachedRepresentationData] = [:]
    private unowned let document: Document

    init(document: Document) {
        self.document = document
    }

    private var storageURL: URL {
        let url = document.fileURL.appendingPathComponent("images")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url
    }

    func store(_ data: Data, for identifier: String) throws {
        let url = storageURL.appendingPathComponent(identifier)
        do {
            try data.write(to: url)
        } catch {
            // TODO Handle error
            print(error)
        }
    }

    func load(_ identifier: String, useCache: Bool = true) -> RepresentationData? {
        let url = storageURL.appendingPathComponent(identifier)

        if let data = cache[identifier]?.representationData {
            return data
        } else if let data = try? Data(contentsOf: url) {
            let representationData = RepresentationData(data)
            if useCache {
                cache[identifier] = CachedRepresentationData(representationData: representationData)
            }
            return representationData
        } else {
            return nil
        }
    }

    func load(asset: Asset, type: RepresentationType, useCache: Bool = true) -> RepresentationData? {
        let representation = asset.representations.filter("rawType = \(type.rawValue)").first
        return representation.flatMap { document.representationManager.load($0.identifier) }
    }
}

extension Document.Filenames {
    internal static let imageStorage = "images"
}
