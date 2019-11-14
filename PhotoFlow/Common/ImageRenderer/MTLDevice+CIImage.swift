//
//  MTLDevice+CIImage.swift
//  ImageRendererUIKit
//
//  Created by Til Blechschmidt on 08.11.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Metal
import CoreImage

extension MTLDevice {
    func makeTexture(from image: CIImage, in context: CIContext, with size: CGSize) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: true
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        
        guard let commandQueue = makeCommandQueue(),
            let buffer = commandQueue.makeCommandBuffer(),
            let texture = makeTexture(descriptor: textureDescriptor)
        else {
            return nil
        }
        
        context.render(image,
                       to: texture,
                       commandBuffer: buffer,
                       bounds: CGRect(x: 0, y: 0, width: texture.width, height: texture.height),
                       colorSpace: CGColorSpaceCreateDeviceRGB())
        
        buffer.commit()
        
        return texture
    }
}
