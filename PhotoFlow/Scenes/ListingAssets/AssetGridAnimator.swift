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
    var originFrame: CGRect
    var image: UIImage

    public static let tag = 99

    init(duration: TimeInterval, isPresenting: Bool, originFrame: CGRect, image: UIImage) {
        self.duration = duration
        self.isPresenting = isPresenting
        self.originFrame = originFrame
        self.image = image
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView

        guard let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from) else { return }
        guard let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else { return }

        self.isPresenting ? container.addSubview(toView) : container.insertSubview(toView, belowSubview: fromView)

        let detailView = isPresenting ? toView : fromView

        guard let targetImageView = detailView.viewWithTag(AssetGridAnimator.tag) as? UIImageView else { return }
        let targetImageFrame = {
            return targetImageView.imageBoundingRect.map({ targetImageView.convert($0, to: detailView) }) ?? targetImageView.frame
        }
        targetImageView.alpha = 0

        let transitionImageView = UIImageView(frame: isPresenting ? originFrame : targetImageFrame())
        transitionImageView.image = image
        container.addSubview(transitionImageView)

//        toView.frame = isPresenting ? CGRect(x: fromView.frame.width, y: 0, width: toView.frame.width, height: toView.frame.height) : toView.frame
        toView.alpha = isPresenting ? 0 : 1
        toView.layoutIfNeeded()

        UIView.animate(withDuration: duration, animations: {
            transitionImageView.frame = self.isPresenting ? targetImageFrame() : self.originFrame
//            detailView.frame = self.isPresenting ? fromView.frame : CGRect(x: toView.frame.width, y: 0, width: toView.frame.width, height: toView.frame.height)
            detailView.alpha = self.isPresenting ? 1 : 0
        }, completion: { (finished) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            transitionImageView.removeFromSuperview()
            targetImageView.alpha = 1
        })
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
}
