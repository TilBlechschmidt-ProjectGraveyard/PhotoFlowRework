//
//  ImageRendererView.swift
//  ImageRenderer
//
//  Created by Til Blechschmidt on 06.11.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import MetalKit

class ImageRendererView: MTKView {
    private let image: CIImage
    private let context: CIContext
    private var mtlTexture: MTLTexture? = nil
    private var pipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    
    private var imageSize: CGSize
    
    internal let imageBoundsView: ImageBoundingRectReadableView
    internal var pinchGestureRecognizer: UIPinchGestureRecognizer!
    internal var panGestureRecognizer: UIPanGestureRecognizer!
    
    init(image: CIImage, originalSize: CGSize, context: CIContext, imageBoundsView: ImageBoundingRectReadableView = ImageBoundingView(), device: MTLDevice! = MTLCreateSystemDefaultDevice()) {
        self.imageBoundsView = imageBoundsView
        self.image = image
        self.context = context
        self.imageSize = originalSize
        
        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "vertexShader")
        let samplerFunction = library.makeFunction(name: "samplingShader")
        
        super.init(frame: .zero, device: device)
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.label = "Texturing Pipeline"
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = samplerFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        self.pipelineState = try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        
        isPaused = true
        enableSetNeedsDisplay = true
        framebufferOnly = false
        delegate = self
        
        // TODO Move this up in the stack or to a public helper function
        pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(userPinched))
        pinchGestureRecognizer.delegate = self
        imageBoundsView.addGestureRecognizer(pinchGestureRecognizer)

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(userPanned))
        panGestureRecognizer.minimumNumberOfTouches = 2
        panGestureRecognizer.delegate = self
        imageBoundsView.addGestureRecognizer(panGestureRecognizer)
        
        addSubview(imageBoundsView)
        imageBoundsView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        aspectFit(bounds.size)
    }
    
    func loadTexture() {
        DispatchQueue.global().async {
            let start = Date()
            self.mtlTexture = self.device?.makeTexture(from: self.image, in: self.context, with: self.imageSize)
            DispatchQueue.main.async {
                print("load \(-start.timeIntervalSinceNow) seconds")
                self.setNeedsDisplay()
            }
        }
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
        
        // TODO Check if this works if the ImageRendererView is parallel to the imageBoundsView
        imageBoundsView.bounds = convert(imageLocation, to: superview!)
        imageBoundsView.center = convert(center, to: superview!)
        
        setNeedsDisplay()
    }
}

extension ImageRendererView: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        aspectFit(bounds.size)
    }
    
    func draw(in view: MTKView) {
        guard let device = self.device,
            let drawable = currentDrawable,
            let passDescriptor = currentRenderPassDescriptor,
            let commandQueue = device.makeCommandQueue(),
            let buffer = commandQueue.makeCommandBuffer(),
            let texture = mtlTexture
        else {
            return
        }
        
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

extension ImageRendererView {
    convenience init?(url: URL, imageBoundsView: ImageBoundingRectReadableView = ImageBoundingView()) {
        guard let filter = CIFilter(imageURL: url, options: [:]) else {
             return nil
        }
        
        self.init(filter: filter, imageBoundsView: imageBoundsView)
    }
    
    convenience init?(data: Data, imageBoundsView: ImageBoundingRectReadableView = ImageBoundingView()) {
        guard let filter = CIFilter(imageData: data, options: [:]) else {
             return nil
        }
        
        self.init(filter: filter, imageBoundsView: imageBoundsView)
    }
    
    convenience init?(filter: CIFilter, imageBoundsView: ImageBoundingRectReadableView = ImageBoundingView()) {
        guard let image = filter.outputImage, let sizeVector = filter.value(forKey: "outputNativeSize") as? CIVector else {
             return nil
        }
        
        let context = CIContext()
        let size = CGSize(width: sizeVector.x, height: sizeVector.y)
        
        self.init(image: image, originalSize: size, context: context, imageBoundsView: imageBoundsView)
    }
}
