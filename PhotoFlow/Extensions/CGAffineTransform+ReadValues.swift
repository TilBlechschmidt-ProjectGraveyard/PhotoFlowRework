//
//  CGAffineTransform+ReadValues.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 26.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import CoreGraphics

extension CGAffineTransform {
    var scaleX: CGFloat { return a }
    var scaleY: CGFloat { return d }
    var translationX: CGFloat { return tx }
    var translationY: CGFloat { return ty }
}
