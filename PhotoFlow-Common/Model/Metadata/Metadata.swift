//
//  ImageMetadata.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 20.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import CoreImage
import CoreGraphics
import CoreLocation
import RealmSwift

@objcMembers
class Metadata: Object {
    dynamic var width: Double = 0
    dynamic var height: Double = 0
    dynamic var rawOrientation = UIImage.Orientation.up.rawValue

    dynamic var tiff: TIFFMetadata? = nil
    dynamic var exif: EXIFMetadata? = nil
    dynamic var aux: EXIFAuxMetadata? = nil

    let latitude = RealmOptional<Double>()
    let longitude = RealmOptional<Double>()

    dynamic var rawHistogram = Data()
}

extension Metadata {
    convenience init?(_ data: Data) {
        self.init()
        
        guard let cgImage = UIImage(data: data)?.cgImage else { return nil }
        histogram = cgImage.calculateNormalizedHistogram()

        guard let image = CIImage(data: data) else { return nil }
        let dict = image.properties

        orientation = dict.take(from: "Orientation").flatMap { UIImage.Orientation(fromExif: $0) } ?? UIImage.Orientation.up
        tiff = dict.take(from: "{TIFF}").flatMap { TIFFMetadata(from: $0) }
        exif = dict.take(from: "{Exif}").flatMap { EXIFMetadata(from: $0) }
        aux = dict.take(from: "{ExifAux}").flatMap { EXIFAuxMetadata(from: $0) }
        location = dict.take(from: "{GPS}").flatMap { CLLocationCoordinate2D(from: $0) }
        
        width = Double(dict.take(from: "PixelWidth") ?? image.extent.width)
        height = Double(dict.take(from: "PixelHeight") ?? image.extent.height)
    }
}

extension Metadata {
    var dimensions: CGSize {
        get {
            return CGSize(width: width, height: height)
        }
        set {
            width = Double(newValue.width)
            height = Double(newValue.height)
        }
    }
    
    var orientation: UIImage.Orientation {
        get {
            return UIImage.Orientation(rawValue: rawOrientation) ?? UIImage.Orientation.up
        }
        set {
            rawOrientation = newValue.rawValue
        }
    }
    
    var histogram: NormalizedHistogram {
        get {
            return NormalizedHistogram.decode(rawHistogram) ?? NormalizedHistogram()
        }
        set {
            rawHistogram = newValue.encode()
        }
    }
    
    var location: CLLocationCoordinate2D? {
        get {
            guard let latitude = latitude.value, let longitude = longitude.value else { return nil }
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        set {
            latitude.value = newValue?.latitude
            longitude.value = newValue?.longitude
        }
    }
}

extension UIImage.Orientation {
    init?(fromExif orientation: Int) {
        self.init(rawValue: orientation - 1)
    }
}
