//
//  ImageRendererView+Gestures.swift
//  ImageRendererUIKit
//
//  Created by Til Blechschmidt on 08.11.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

extension ImageRendererView {
    @objc func userPanned(recognizer: UIPanGestureRecognizer) {
        let view = imageBoundsView
        let translation = recognizer.translation(in: view)
        let translateX = translation.x
        let translateY = translation.y

        view.transform = view.transform
            .translatedBy(x: translateX, y: translateY)

        recognizer.setTranslation(.zero, in: view)
        setNeedsDisplay()
    }
    
    @objc func userPinched(_ recognizer: UIPinchGestureRecognizer) {
        let view = imageBoundsView
        let bounds = view.bounds
        var center = recognizer.location(in: view)
        center.x -= bounds.midX
        center.y -= bounds.midY

        let transform = view.transform
            .translatedBy(x: center.x, y: center.y)
            .scaledBy(x: recognizer.scale, y: recognizer.scale)
            .translatedBy(x: -center.x, y: -center.y)

        switch recognizer.state {
        case .changed:
            view.transform = transform
        case .ended where transform.scaleX < 1:
            UIView.animate(withDuration: 0.25, delay: 0, options: [.allowAnimatedContent, .layoutSubviews], animations: {
                view.transform = CGAffineTransform.identity
            }, completion: nil)
            break
        default:
            break
        }

        recognizer.scale = 1.0
        setNeedsDisplay()
    }
}

extension ImageRendererView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == pinchGestureRecognizer && otherGestureRecognizer == panGestureRecognizer
            || gestureRecognizer == panGestureRecognizer && otherGestureRecognizer == pinchGestureRecognizer
    }
}
