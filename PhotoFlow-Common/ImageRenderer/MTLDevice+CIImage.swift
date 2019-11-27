//
//  MTLDevice+CIImage.swift
//  ImageRendererUIKit
//
//  Created by Til Blechschmidt on 08.11.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Metal
import MetalKit

extension MTLDevice {
    func makeTexture(from imageData: Data) throws -> MTLTexture {
        let loader = MTKTextureLoader(device: self)
        
        let options: [MTKTextureLoader.Option : Any] = [
            MTKTextureLoader.Option.generateMipmaps: NSNumber(booleanLiteral: false),
            MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.flippedVertically
        ]
        
        return try loader.newTexture(data: imageData, options: options)
    }
}
