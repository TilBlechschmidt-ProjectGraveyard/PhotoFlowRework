//
//  UIImageView+ImageBoundingRect.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 14.11.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

protocol ImageBoundingRectReadableView: UIView {
    var imageBoundingRect: CGRect? { get }
}

class ImageBoundingView: UIView, ImageBoundingRectReadableView {
    var imageBoundingRect: CGRect? {
        return self.frame
    }
}

extension UIImageView: ImageBoundingRectReadableView {
    var imageBoundingRect: CGRect? {
        if let image = self.image {
            let boundsScale = self.bounds.size.width / self.bounds.size.height
            let imageScale = image.size.width / image.size.height

            var drawingRect: CGRect = self.bounds

            if boundsScale > imageScale {
                drawingRect.size.width =  drawingRect.size.height * imageScale
                drawingRect.origin.x = (self.bounds.size.width - drawingRect.size.width) / 2
            } else {
                drawingRect.size.height = drawingRect.size.width / imageScale
                drawingRect.origin.y = (self.bounds.size.height - drawingRect.size.height) / 2
            }

            return drawingRect
        } else {
            return nil
        }
    }
}
