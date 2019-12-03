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
    private let imageBoundsView = ImageBoundingView()
    private var imageBoundsAlphaObserverToken: NSKeyValueObservation?
    
    private var rendererView: ImageRendererView?

    private let navigationWrapperView = UIView()
    private let nextImageView = UIImageView(image: UIImage(systemName: "arrow.right.circle.fill"))
    private let prevImageView = UIImageView(image: UIImage(systemName: "arrow.left.circle.fill"))

    private let acceptedImageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
    private let rejectedImageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
    
    private var initialScale: CGFloat = 1
    
    private lazy var pinchGestureRecognizer: UIPinchGestureRecognizer
        = UIPinchGestureRecognizer(target: self, action: #selector(userPinched))
    
    private lazy var panGestureRecognizer: UIPanGestureRecognizer
        = UIPanGestureRecognizer(target: self, action: #selector(userPanned))

    weak var delegate: RepresentationViewControllerDelegate?
    
    public var representationData: RepresentationData? {
        didSet {
            if let rendererData = representationData?.rendererData {
                self.rendererView?.removeFromSuperview()
                
                let rendererView = ImageRendererView(rendererData, imageBoundsView: imageBoundsView)
                rendererView.backgroundColor = view.backgroundColor
                
                view.addSubview(rendererView)
                view.sendSubviewToBack(rendererView)
                rendererView.snp.makeConstraints { make in
                    make.left.equalToSuperview()
                    make.right.equalToSuperview()
                    make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
                    make.bottom.equalToSuperview()
                }
                
                self.rendererView = rendererView
            } else {
                rendererView = nil
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupGestures()
        setupObservers()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Image View
        imageBoundsView.tag = AssetGridAnimator.tag
        view.addSubview(imageBoundsView)
        // Will be placed by ImageRendererView (bad practice ... change that)

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
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalToSuperview()
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
        imageBoundsView.addGestureRecognizer(acceptGestureRecognizer)

        let rejectGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(rejectAsset))
        rejectGestureRecognizer.numberOfTapsRequired = 2
        rejectGestureRecognizer.numberOfTouchesRequired = 2
        imageBoundsView.addGestureRecognizer(rejectGestureRecognizer)

        let dismissGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(dismissSelf))
        dismissGestureRecognizer.direction = .down
        dismissGestureRecognizer.numberOfTouchesRequired = 1
        imageBoundsView.addGestureRecognizer(dismissGestureRecognizer)
        
        let zoomGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleZoom))
        zoomGestureRecognizer.numberOfTapsRequired = 2
        zoomGestureRecognizer.numberOfTouchesRequired = 1
        imageBoundsView.addGestureRecognizer(zoomGestureRecognizer)
        
        let horizontalPanGestureRecognizer = PanDirectionGestureRecognizer(direction: .horizontal)
        horizontalPanGestureRecognizer.leftActionView = prevImageView
        horizontalPanGestureRecognizer.rightActionView = nextImageView
        horizontalPanGestureRecognizer.draggableView = navigationWrapperView
        horizontalPanGestureRecognizer.onImmediateSuccessfulSwipe = { [unowned self] in
            if $0 {
                self.delegate?.representationViewControllerSwipedBackwards()
            } else {
                self.delegate?.representationViewControllerSwipedForward()
            }
        }
        imageBoundsView.addGestureRecognizer(horizontalPanGestureRecognizer)
        
        pinchGestureRecognizer.delegate = self
        imageBoundsView.addGestureRecognizer(pinchGestureRecognizer)

        panGestureRecognizer.minimumNumberOfTouches = 2
        panGestureRecognizer.delegate = self
        imageBoundsView.addGestureRecognizer(panGestureRecognizer)
    }
    
    private func setupObservers() {
        imageBoundsAlphaObserverToken = imageBoundsView.observe(\.alpha) { [unowned self] object, change in
            self.rendererView?.alpha = self.imageBoundsView.alpha
        }
    }
}

// MARK: - Gestures
extension RepresentationViewController {
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
        let view = imageBoundsView
        let bounds = view.bounds
        var center = recognizer.location(in: view)
        center.x -= bounds.midX
        center.y -= bounds.midY
        
        // TODO Calculate this from the screen to pixel ratio
        let pixelPerfectScale: CGFloat = 3
        
        UIView.animate(withDuration: 0.25, delay: 0, options: [.allowAnimatedContent], animations: { [unowned self] in
            if view.transform.scaleX > 1 || view.transform.translationX != 0 || view.transform.translationY != 0 {
                let inverseScale = 1 / view.transform.scaleX
                view.transform = view.transform.scaledBy(x: inverseScale, y: inverseScale).translatedBy(x: -view.transform.translationX, y: -view.transform.translationY)
            } else if view.transform.scaleX == 1 {
                view.transform = view.transform
                    .translatedBy(x: center.x, y: center.y)
                    .scaledBy(x: pixelPerfectScale, y: pixelPerfectScale)
                    .translatedBy(x: -center.x, y: -center.y)
            }
            
            self.rendererView?.setNeedsDisplay()
        }, completion: nil)
    }
    
    @objc func userPanned(recognizer: UIPanGestureRecognizer) {
        let view = imageBoundsView
        let translation = recognizer.translation(in: view)
        let translateX = translation.x
        let translateY = translation.y

        view.transform = view.transform
            .translatedBy(x: translateX, y: translateY)

        recognizer.setTranslation(.zero, in: view)
        rendererView?.setNeedsDisplay()
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
        default:
            break
        }

        recognizer.scale = 1.0
        rendererView?.setNeedsDisplay()
    }
}

extension RepresentationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == pinchGestureRecognizer && otherGestureRecognizer == panGestureRecognizer
            || gestureRecognizer == panGestureRecognizer && otherGestureRecognizer == pinchGestureRecognizer
    }
}
