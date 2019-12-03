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
    let device: MTLDevice
    let texture: MTLTexture

    init(data: Data, device: MTLDevice) {
        self.device = device
        self.texture = device.makeTexture(from: data)!
    }
}
