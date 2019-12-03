//
//  MTLDevice+CIImage.swift
//  ImageRendererUIKit
//
//  Created by Til Blechschmidt on 08.11.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Metal
import MetalKit
import Combine

extension MTLDevice {
    func makeTexture(from imageData: Data) -> MTLTexture? // Future<MTLTexture, Error> {
        let loader = MTKTextureLoader(device: self)
        
        let options: [MTKTextureLoader.Option : Any] = [
            MTKTextureLoader.Option.generateMipmaps: NSNumber(booleanLiteral: false),
            MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.flippedVertically,
            MTKTextureLoader.Option.SRGB: NSNumber(booleanLiteral: true)
        ]
        
//        return Future<MTLTexture, Error> { observer in
//            do {
//                let texture = try loader.newTexture(data: imageData, options: options)
//                observer(.success(texture))
//            } catch {
//                observer(.failure(error))
//            }
//        }
        
        var texture: MTLTexture? = nil
        
        do {
            texture = try loader.newTexture(data: imageData, options: options)
        } catch {
            // TODO Handle non-null orientation properly
//            texture = renderCIImageTexture(from: imageData)
        }
        
        return texture
    }
    
    private func renderCIImageTexture(from imageData: Data) -> MTLTexture? {
        guard let filter = CIFilter(imageData: imageData, options: [:]), let image = filter.outputImage, let sizeVector = filter.value(forKey: "outputNativeSize") as? CIVector else {
             return nil
        }
        
        let context = CIContext()
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb,
            width: Int(sizeVector.x),
            height: Int(sizeVector.y),
            mipmapped: true
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        
        guard let commandQueue = makeCommandQueue(),
            let buffer = commandQueue.makeCommandBuffer(),
            let texture = makeTexture(descriptor: textureDescriptor)
        else {
            return nil
        }
        
        print(texture.width, texture.height)
        
        context.render(image,
                       to: texture,
                       commandBuffer: buffer,
                       bounds: CGRect(x: 0, y: 0, width: texture.width, height: texture.height),
                       colorSpace: CGColorSpaceCreateDeviceRGB())
        
        buffer.commit()
        buffer.waitUntilCompleted()
        
        return texture
    }
}
