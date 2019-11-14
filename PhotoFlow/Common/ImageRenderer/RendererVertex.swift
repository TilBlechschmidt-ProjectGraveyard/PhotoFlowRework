//
//  RendererVertex.swift
//  ImageRendererUIKit
//
//  Created by Til Blechschmidt on 08.11.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import CoreGraphics

struct RendererVertex {
    let position: (Float, Float)
    let textureCoordinate: (Float, Float)
    
    init(position: (CGFloat, CGFloat), textureCoordinate: (CGFloat, CGFloat)) {
        self.position = (Float(position.0), Float(position.1))
        self.textureCoordinate = (Float(textureCoordinate.0), Float(textureCoordinate.1))
    }
}
