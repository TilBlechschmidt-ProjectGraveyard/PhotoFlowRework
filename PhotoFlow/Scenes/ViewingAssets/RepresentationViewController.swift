//
//  RepresentationViewController.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 29.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

protocol RepresentationViewControllerDelegate: class {
    func representationViewControllerDidAcceptAsset()
    func representationViewControllerDidRejectAsset()

    func representationViewControllerSwipedForward()
    func representationViewControllerSwipedBackwards()
    func representationViewControllerSwipedDownwards()
}

class RepresentationViewController: UIViewController {
    private let imageView = UIImageView()

    private let navigationWrapperView = UIView()
    private let nextImageView = UIImageView(image: UIImage(systemName: "arrow.right.circle.fill"))
    private let prevImageView = UIImageView(image: UIImage(systemName: "arrow.left.circle.fill"))

    private let acceptedImageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
    private let rejectedImageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))

    private var initialScale: CGFloat = 1
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var pinchGestureRecognizer: UIPinchGestureRecognizer!

    weak var delegate: RepresentationViewControllerDelegate?

    var image: UIImage? = nil {
        didSet {
            imageView.image = image
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupGestures()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Image View
        imageView.tag = AssetGridAnimator.tag
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalToSuperview()
        }

        // Next / Prev arrows
        nextImageView.tintColor = .white
        prevImageView.tintColor = .white
        nextImageView.alpha = 0
        prevImageView.alpha = 0
        navigationWrapperView.isUserInteractionEnabled = false
        view.addSubview(navigationWrapperView)
        navigationWrapperView.addSubview(nextImageView)
        navigationWrapperView.addSubview(prevImageView)
        navigationWrapperView.snp.makeConstraints { make in
            make.edges.equalTo(imageView)
        }
        prevImageView.snp.makeConstraints { make in
            make.left.equalTo(navigationWrapperView).inset(Constants.spacing)
            make.centerY.equalTo(navigationWrapperView)
            make.width.equalTo(50)
            make.height.equalTo(50)
        }
        nextImageView.snp.makeConstraints { make in
            make.right.equalTo(navigationWrapperView).inset(Constants.spacing)
            make.centerY.equalTo(navigationWrapperView)
            make.width.equalTo(50)
            make.height.equalTo(50)
        }
    }

    private func setupGestures() {
        let acceptGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(acceptAsset))
        acceptGestureRecognizer.numberOfTapsRequired = 1
        acceptGestureRecognizer.numberOfTouchesRequired = 2
        imageView.addGestureRecognizer(acceptGestureRecognizer)

        let rejectGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(rejectAsset))
        rejectGestureRecognizer.numberOfTapsRequired = 2
        rejectGestureRecognizer.numberOfTouchesRequired = 2
        imageView.addGestureRecognizer(rejectGestureRecognizer)

        let dismissGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(dismissSelf))
        dismissGestureRecognizer.direction = .down
        dismissGestureRecognizer.numberOfTouchesRequired = 1
        imageView.addGestureRecognizer(dismissGestureRecognizer)
        
        let zoomGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleZoom))
        zoomGestureRecognizer.numberOfTapsRequired = 2
        zoomGestureRecognizer.numberOfTouchesRequired = 1
        imageView.addGestureRecognizer(zoomGestureRecognizer)
        
        let horizontalPanGestureRecognizer = PanDirectionGestureRecognizer(direction: .horizontal)
        horizontalPanGestureRecognizer.leftActionView = prevImageView
        horizontalPanGestureRecognizer.rightActionView = nextImageView
        horizontalPanGestureRecognizer.draggableView = navigationWrapperView
        horizontalPanGestureRecognizer.onImmediateSuccessfulSwipe = {
            if $0 {
                self.delegate?.representationViewControllerSwipedBackwards()
            } else {
                self.delegate?.representationViewControllerSwipedForward()
            }
        }
        imageView.addGestureRecognizer(horizontalPanGestureRecognizer)

        pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(userPinched))
        pinchGestureRecognizer.delegate = self
        imageView.addGestureRecognizer(pinchGestureRecognizer)

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(userPanned))
        panGestureRecognizer.minimumNumberOfTouches = 2
        panGestureRecognizer.delegate = self
        imageView.addGestureRecognizer(panGestureRecognizer)
    }

    @objc func acceptAsset() {
        delegate?.representationViewControllerDidAcceptAsset()
    }

    @objc func rejectAsset() {
        delegate?.representationViewControllerDidRejectAsset()
    }
    
    @objc func dismissSelf() {
        delegate?.representationViewControllerSwipedDownwards()
    }
    
    @objc func toggleZoom(recognizer: UITapGestureRecognizer) {
        let view = imageView
        let bounds = view.bounds
        var center = recognizer.location(in: view)
        center.x -= bounds.midX;
        center.y -= bounds.midY;
        
        UIView.animate(withDuration: 0.25, animations: {
            if view.transform.scaleX > 1 || view.transform.translationX != 0 || view.transform.translationY != 0 {
                let inverseScale = 1 / view.transform.scaleX
                view.transform = view.transform.scaledBy(x: inverseScale, y: inverseScale).translatedBy(x: -view.transform.translationX, y: -view.transform.translationY)
            } else if view.transform.scaleX == 1 {
                view.transform = view.transform
                    .translatedBy(x: center.x, y: center.y)
                    .scaledBy(x: 3, y: 3)
                    .translatedBy(x: -center.x, y: -center.y)
            }
        })
    }

    @objc func userPanned(recognizer: UIPanGestureRecognizer) {
        let view = imageView
        let translation = recognizer.translation(in: view)
        let translateX = translation.x
        let translateY = translation.y

        view.transform = view.transform
            .translatedBy(x: translateX, y: translateY)

        recognizer.setTranslation(.zero, in: view)
    }

    @objc func userPinched(recognizer: UIPinchGestureRecognizer) {
        let view = imageView
        let bounds = view.bounds
        var center = recognizer.location(in: view)
        center.x -= bounds.midX;
        center.y -= bounds.midY;

        let transform = view.transform
            .translatedBy(x: center.x, y: center.y)
            .scaledBy(x: recognizer.scale, y: recognizer.scale)
            .translatedBy(x: -center.x, y: -center.y)

        switch recognizer.state {
        case .began:
            initialScale = view.transform.scaleX
        case .changed:
            view.transform = transform
        case .ended where transform.scaleX < 0.5 && initialScale == 1:
            self.navigationController?.popViewController(animated: true)
        case .ended where transform.scaleX < 1:
            UIView.animate(withDuration: 0.25) {
                view.transform = CGAffineTransform.identity
            }
            break
        case .ended where transform.scaleX > 1:
            // TODO Implement rendering of RAW image at necessary scale with no interpolation
            break
        default:
            break
        }

        recognizer.scale = 1.0
    }
}

extension RepresentationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == pinchGestureRecognizer && otherGestureRecognizer == panGestureRecognizer
            || gestureRecognizer == panGestureRecognizer && otherGestureRecognizer == pinchGestureRecognizer
    }
}
