//
//  AssetGridAnimator.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 24.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

class AssetGridAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var duration: TimeInterval
    var isPresenting: Bool
    var image: UIImage

    public static let tag = 99

    init(duration: TimeInterval, isPresenting: Bool, image: UIImage) {
        self.duration = duration
        self.isPresenting = isPresenting
        self.image = image
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView

        // Get source and destination views and insert them
        guard let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from) else {
            return
        }
        guard let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else {
            return
        }
        self.isPresenting ? container.addSubview(toView) : container.insertSubview(toView, belowSubview: fromView)
        
        // Extract the source and destination image views
        guard let fromImageView = fromView.viewWithTag(AssetGridAnimator.tag) as? ImageBoundingRectReadableView else {
            return
        }
        guard let toImageView = toView.viewWithTag(AssetGridAnimator.tag) as? ImageBoundingRectReadableView else {
            return
        }
        
        // Create temporary transition image
        let transitionImageView = UIImageView(image: image)
        container.addSubview(transitionImageView)
        
        // Set the target view alpha
        toView.alpha = isPresenting ? 0 : 1
        toView.layoutIfNeeded()
        
        // Read alpha values
        let fromAlpha = fromImageView.alpha
        let toAlpha = toImageView.alpha
        
        // Hide source & destination image until animation completes
        fromImageView.alpha = 0
        toImageView.alpha = 0
        transitionImageView.alpha = fromAlpha
        
        // Extract source and destination image frame
        let detailView = isPresenting ? toView : fromView // TODO Figure this one out.
        let fromFrame = fromImageView.imageBoundingRect.map({ fromImageView.convert($0, to: detailView) }) ?? fromImageView.frame
        let toFrame = toImageView.imageBoundingRect.map({ toImageView.convert($0, to: detailView) }) ?? toImageView.frame
        
        // Set the initial frame
        transitionImageView.frame = fromFrame
        
        UIView.animate(withDuration: duration, animations: {
            transitionImageView.frame = toFrame
            transitionImageView.alpha = toAlpha
            detailView.alpha = self.isPresenting ? 1 : 0 // TODO Figure this one out.
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            transitionImageView.removeFromSuperview()
            fromImageView.alpha = fromAlpha
            toImageView.alpha = toAlpha
        })
    }

//    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
//        let container = transitionContext.containerView
//
//        guard let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from) else { return }
//        guard let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else { return }
//
//        self.isPresenting ? container.addSubview(toView) : container.insertSubview(toView, belowSubview: fromView)
//        
//        print(isPresenting)
//
//        let detailView = isPresenting ? toView : fromView
//
//        guard let targetImageView = detailView.viewWithTag(AssetGridAnimator.tag) as? UIImageView else { return }
//        let targetImageFrame = {
//            return targetImageView.imageBoundingRect.map({ targetImageView.convert($0, to: detailView) }) ?? targetImageView.frame
//        }
//        targetImageView.alpha = 0
//
//        let transitionImageView = UIImageView(frame: isPresenting ? originFrame : targetImageFrame())
//        transitionImageView.image = image
//        container.addSubview(transitionImageView)
//
////        toView.frame = isPresenting ? CGRect(x: fromView.frame.width, y: 0, width: toView.frame.width, height: toView.frame.height) : toView.frame
//        toView.alpha = isPresenting ? 0 : 1
//        toView.layoutIfNeeded()
//
//        UIView.animate(withDuration: duration, animations: {
//            transitionImageView.frame = self.isPresenting ? targetImageFrame() : self.originFrame
////            detailView.frame = self.isPresenting ? fromView.frame : CGRect(x: toView.frame.width, y: 0, width: toView.frame.width, height: toView.frame.height)
//            detailView.alpha = self.isPresenting ? 1 : 0
//        }, completion: { (finished) in
//            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
//            transitionImageView.removeFromSuperview()
//            targetImageView.alpha = 1
//        })
//    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
}
