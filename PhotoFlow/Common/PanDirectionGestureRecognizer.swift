//
//  PanDirectionGestureRecognizer.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 26.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit.UIGestureRecognizerSubclass

enum PanDirection {
    case vertical
    case horizontal
}

class PanDirectionGestureRecognizer: UIPanGestureRecognizer {
    let direction: PanDirection

    init(direction: PanDirection, target: AnyObject? = nil, action: Selector? = nil) {
        self.direction = direction
        super.init(target: target, action: action)
        addTarget(self, action: #selector(handleAction(recognizer:)))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        if state == .began {
            let vel = velocity(in: view)
            switch direction {
            case .horizontal where abs(vel.y) > abs(vel.x):
                state = .cancelled
            case .vertical where abs(vel.x) > abs(vel.y):
                state = .cancelled
            default:
                break
            }
        }
    }

    var distanceLimit: CGFloat = 50
    weak var leftActionView: UIView?
    weak var rightActionView: UIView?
    weak var draggableView: UIView?

    var onSuccessfulSwipe: ((Bool) -> Void)?
    var onImmediateSuccessfulSwipe: ((Bool) -> Void)?

    @objc func handleAction(recognizer: PanDirectionGestureRecognizer) {
        guard let view = self.view else { return }

        let translation = recognizer.translation(in: view)

        let clampedTranslation = min(max(translation.x, -distanceLimit), distanceLimit)
        let distancePercentage = clampedTranslation / distanceLimit
        let easedPercentage = sin(distancePercentage * CGFloat.pi / 2)
        let easedTranslation = distanceLimit * easedPercentage
        let actionScale = abs(easedPercentage) * 0.5 + 0.5

        let transform = CGAffineTransform(translationX: easedTranslation, y: 0)
        let actionTransform = CGAffineTransform(scaleX: actionScale, y: actionScale)

        if distancePercentage > 0 {
            rightActionView?.alpha = 0
            leftActionView?.transform = actionTransform
            leftActionView?.alpha = abs(easedPercentage)
        } else {
            leftActionView?.alpha = 0
            rightActionView?.transform = actionTransform
            rightActionView?.alpha = abs(easedPercentage)
        }

        switch recognizer.state {
        case .possible:
            break
        case .began:
            fallthrough
        case .changed:
            draggableView?.transform = transform
        case .ended:
            fallthrough
        case .cancelled:
            fallthrough
        case .failed:
            fallthrough
        default:
            UIView.animate(
                withDuration: 0.5,
                animations: {
                    self.leftActionView?.alpha = 0
                    self.rightActionView?.alpha = 0
                    self.draggableView?.transform = CGAffineTransform.identity

                    if abs(distancePercentage) == 1 {
                        self.onImmediateSuccessfulSwipe?(distancePercentage > 0)
                    }
                },
                completion: { _ in
                    if abs(distancePercentage) == 1 {
                        self.onSuccessfulSwipe?(distancePercentage > 0)
                    }
                }
            )
        }
    }
}
