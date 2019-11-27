//
//  RepresentationManager.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 24.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import UIKit
import CoreImage
import Metal

class RepresentationData {
    let data: Data
    let image: UIImage?
    let rendererData: ImageRendererData?

    init(_ data: Data, context: CIContext, device: MTLDevice, initializeRenderer: Bool) {
        self.data = data
        image = UIImage(data: data)
        rendererData = initializeRenderer ? ImageRendererData(data: data, device: device) : nil // , context: context
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
    case noRenderingDeviceAvailable
}

class RepresentationManager {
    private var cache: [String: CachedRepresentationData] = [:]
    private unowned let document: Document
    private let context: CIContext
    private let device: MTLDevice

    init(document: Document, context: CIContext = CIContext(), device: MTLDevice? = nil) throws {
        guard let device = device ?? MTLCreateSystemDefaultDevice() else {
            throw RepresentationManagerError.noRenderingDeviceAvailable
        }
        
        self.document = document
        self.context = context
        self.device = device
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

    func representationID(for asset: Asset, type: RepresentationType) -> String? {
        let representation = asset.representations.filter("rawType = \(type.rawValue)").first
        return representation?.identifier
    }

    func load(asset: Asset, type: RepresentationType, useCache: Bool = true) -> RepresentationData? {
        return representationID(for: asset, type: type).flatMap {
            return document.representationManager.load($0, initializeRenderer: type == .original)
        }
    }

    func load(_ identifier: String, initializeRenderer: Bool = false, useCache: Bool = true) -> RepresentationData? {
        let url = storageURL.appendingPathComponent(identifier)

        if let data = cache[identifier]?.representationData {
            return data
        } else if let data = try? Data(contentsOf: url) {
            let context = CIContext()
            let representationData = RepresentationData(data, context: context, device: device, initializeRenderer: initializeRenderer)
            if useCache {
                cache[identifier] = CachedRepresentationData(representationData: representationData)
            }
            return representationData
        } else {
            return nil
        }
    }
}

extension Document.Filenames {
    internal static let imageStorage = "images"
}
