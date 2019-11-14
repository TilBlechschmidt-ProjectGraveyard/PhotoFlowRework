//
//  ImageRendererData.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 14.11.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import CoreImage
import Metal

struct ImageRendererData {
    let image: CIImage
    let context: CIContext
    
    let texture: MTLTexture
    
    init?(url: URL, context: CIContext, device: MTLDevice) {
        guard let filter = CIFilter(imageURL: url, options: [:]) else {
             return nil
        }
        
        self.init(filter: filter, context: context, device: device)
    }
    
    init?(data: Data, context: CIContext, device: MTLDevice) {
        guard let filter = CIFilter(imageData: data, options: [:]) else {
             return nil
        }
        
        self.init(filter: filter, context: context, device: device)
    }
    
    init?(filter: CIFilter, context: CIContext, device: MTLDevice) {
        guard let image = filter.outputImage, let sizeVector = filter.value(forKey: "outputNativeSize") as? CIVector else {
             return nil
        }
        
        let size = CGSize(width: sizeVector.x, height: sizeVector.y)
        
        guard let texture = device.makeTexture(from: image, in: context, with: size) else {
            return nil
        }
        
        self.image = image
        self.context = context
        
        self.texture = texture
        
        // TODO Figure out a way to prime the rendering pipeline / pre-load the texture
    }
}
