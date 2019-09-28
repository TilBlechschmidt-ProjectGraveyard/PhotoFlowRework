//
//  CGImage+Thumbnail.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 24.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import CoreGraphics
import ImageIO
import UIKit

extension CGImage {
    static func thumbnail(for url: URL, maximumSideLength: CGFloat = 1280) -> Data? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        return thumbnail(for: src, maximumSideLength: maximumSideLength)
    }

    static func thumbnail(for data: Data, maximumSideLength: CGFloat = 1280) -> Data? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        return thumbnail(for: src, maximumSideLength: maximumSideLength)
    }

    static func thumbnail(for src: CGImageSource, maximumSideLength: CGFloat) -> Data? {
        let options: [NSObject: AnyObject] = [
            kCGImageSourceShouldAllowFloat : true as CFBoolean,
            kCGImageSourceCreateThumbnailWithTransform : true as CFBoolean,
            kCGImageSourceCreateThumbnailFromImageAlways : true as CFBoolean,
            kCGImageSourceThumbnailMaxPixelSize : maximumSideLength as CFNumber
        ]

        guard let imref = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary) else {
            return nil
        }

        let thumbnail = UIImage(cgImage: imref, scale: UIScreen.main.scale, orientation: .up)
        return thumbnail.jpegData(compressionQuality: 0.8)
    }

    static func preload(from data: Data) -> UIImage? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let options: [NSObject: AnyObject] = [
            kCGImageSourceShouldCache : true as CFBoolean,
            kCGImageSourceShouldCacheImmediately : true as CFBoolean
        ]

        guard let imref = CGImageSourceCreateImageAtIndex(src, 0, options as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: imref, scale: UIScreen.main.scale, orientation: .up)
    }
}
