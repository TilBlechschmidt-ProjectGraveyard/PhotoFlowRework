//
//  UIView+Blur.swift
//  PhotoFlow
//
//  Created by Noah Peeters on 08.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

extension UIView {
    @discardableResult func blur(style: UIBlurEffect.Style, cornerRadius: CGFloat? = nil, corners: CACornerMask? = nil) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.isUserInteractionEnabled = false
        blurEffectView.clipsToBounds = true

        if let cornerRadius = cornerRadius {
            blurEffectView.layer.cornerRadius = cornerRadius
            self.layer.cornerRadius = cornerRadius
        }

        if let corners = corners {
            blurEffectView.layer.maskedCorners = corners
            self.layer.maskedCorners = corners
        }

        self.addSubview(blurEffectView)
        self.sendSubviewToBack(blurEffectView)
        return blurEffectView
    }
}
