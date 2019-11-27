//
//  ImageRendererView.swift
//  ImageRenderer
//
//  Created by Til Blechschmidt on 06.11.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import MetalKit

// MARK: - Class definition
class ImageRendererView: MTKView {
    // MARK: Properties
    private let rendererData: ImageRendererData
    private lazy var pipelineState: MTLRenderPipelineState? = createRenderPipelineState()
    
    private lazy var imageSize: CGSize = CGSize(width: rendererData.texture.width, height: rendererData.texture.height)
    
    private let imageBoundsView: ImageBoundingRectReadableView
    
    override var backgroundColor: UIColor? {
        didSet {
            if let color = self.backgroundColor {
                let (red, green, blue, alpha) = color.rgba
                clearColor = MTLClearColor(red: Double(red), green: Double(green), blue: Double(blue), alpha: Double(alpha))
            }
        }
    }
    
    // MARK: Initializers
    init(_ rendererData: ImageRendererData, imageBoundsView: ImageBoundingRectReadableView) {
        self.rendererData = rendererData
        self.imageBoundsView = imageBoundsView
        
        super.init(frame: .zero, device: rendererData.device)
        
        isPaused = true
        enableSetNeedsDisplay = true
        framebufferOnly = false
        delegate = self
        colorPixelFormat = .bgra8Unorm_srgb
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createRenderPipelineState() -> MTLRenderPipelineState? {
        let library = device?.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let samplerFunction = library?.makeFunction(name: "samplingShader")
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.label = "Texturing Pipeline"
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = samplerFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        return try? device?.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    }
    
    // MARK: Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        aspectFit(bounds.size)
    }
    
    private func aspectFit(_ size: CGSize) {
        // Calculate target dimensions with aspectRatioFit
        let imageRatio = imageSize.width / imageSize.height
        let viewRatio = size.width / size.height
        
        let dimensions = viewRatio > imageRatio
            ? CGSize(width: imageSize.width * size.height / imageSize.height, height: size.height)
            : CGSize(width: size.width, height: imageSize.height * size.width / imageSize.width)
        
        let origin = CGPoint(x: (size.width - dimensions.width) / 2, y: (size.height - dimensions.height) / 2)
        
        let imageLocation = CGRect(
            origin: origin,
            size: dimensions
        )
        
        // TODO Remove force unwraps
        imageBoundsView.bounds = convert(imageLocation, to: superview!)
        imageBoundsView.center = convert(center, to: superview!)
        
        setNeedsDisplay()
    }
}

// MARK: - Rendering
extension ImageRendererView: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        aspectFit(bounds.size)
    }
    
    func draw(in view: MTKView) {
        guard let device = device,
            let drawable = currentDrawable,
            let passDescriptor = currentRenderPassDescriptor,
            let commandQueue = device.makeCommandQueue(),
            let buffer = commandQueue.makeCommandBuffer(),
            let pipelineState = pipelineState
        else {
            return
        }
        
        let texture = rendererData.texture
        let vertices = calculateVertices()
        
        let commandEncoder = buffer.makeRenderCommandEncoder(descriptor: passDescriptor)!
        commandEncoder.setRenderPipelineState(pipelineState)
        commandEncoder.setVertexBytes(vertices, length: MemoryLayout<RendererVertex>.stride * vertices.count, index: 0)
        commandEncoder.setFragmentTexture(texture, index: 0)

        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        commandEncoder.endEncoding()
        
        buffer.present(drawable)
        buffer.commit()
    }
    
    private func convertToMetalCoordinate(viewCoordinate: CGPoint) -> CGPoint {
        let viewSize = bounds.size
        
        let widthPercentage = viewCoordinate.x / viewSize.width
        let targetX = widthPercentage * 2 - 1
        
        // Note: In UIKit the y-axis is flipped!
        let heightPercentage = viewCoordinate.y / viewSize.height
        let targetY = heightPercentage * 2 - 1
        
        // This is supposed to work: viewCoordinate / (viewSize / 2.0)
        
        return CGPoint(x: targetX, y: targetY)
    }
    
    private func calculateVertices() -> [RendererVertex] {
        // Calculate transformed target rect
        // TODO: Coordinate system transformation is probably necessary at this point
        let imageLocation = imageBoundsView.frame
        let maxPoint = CGPoint(x: imageLocation.maxX, y: imageLocation.maxY)
        
        // Convert to metal coordinate space
        let metalOrigin = convertToMetalCoordinate(viewCoordinate: imageLocation.origin)
        let metalMaxPoint = convertToMetalCoordinate(viewCoordinate: maxPoint)
        
        // Calculate metal bounding rect
        let metalRect = CGRect(
            origin: metalOrigin,
            size: CGSize(width: metalMaxPoint.x - metalOrigin.x, height: metalMaxPoint.y - metalOrigin.y)
        ).applying(CGAffineTransform(scaleX: 1, y: -1))
        
        // Generate vertices
        return [
            // Left triangle
            RendererVertex(position: (metalRect.maxX, metalRect.minY), textureCoordinate: (1.0, 0.0)), // bottom right
            RendererVertex(position: (metalRect.minX, metalRect.minY), textureCoordinate: (0.0, 0.0)), // bottom left
            RendererVertex(position: (metalRect.minX, metalRect.maxY), textureCoordinate: (0.0, 1.0)), // top left
            
            // Right triangle
            RendererVertex(position: (metalRect.maxX, metalRect.minY), textureCoordinate: (1.0, 0.0)), // bottom right
            RendererVertex(position: (metalRect.minX, metalRect.maxY), textureCoordinate: (0.0, 1.0)), // top left
            RendererVertex(position: (metalRect.maxX, metalRect.maxY), textureCoordinate: (1.0, 1.0))  // top right
        ]
    }
}
