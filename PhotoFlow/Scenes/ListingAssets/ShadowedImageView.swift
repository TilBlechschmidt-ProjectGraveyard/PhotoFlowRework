//
//  ShadowedImageView.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 24.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

class ShadowedImageView: UIView {
    static let cornerRadius: CGFloat = 5

    private let borderLayer = CAShapeLayer()
    let imageView = UIImageView()

    var image: UIImage? {
        didSet {
            imageView.image = image
            updateShadow()
        }
    }

    override var contentMode: UIView.ContentMode {
        didSet {
            imageView.contentMode = contentMode
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateShadow()
    }

    init() {
        super.init(frame: .zero)

        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        setupShadow()
        setupBorder()
        imageView.layer.cornerRadius = ShadowedImageView.cornerRadius
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var imageBoundingRect: CGRect? {
        return imageView.imageBoundingRect.map { imageView.convert($0, to: self) }
    }

    private func updateShadow() {
        guard let boundingRect = imageBoundingRect else {
            return
        }

        // Calculate the edge path and build a matching mask from it.
        let radius: CGFloat = ShadowedImageView.cornerRadius
        let path = UIBezierPath(roundedRect: boundingRect, cornerRadius: radius)
        let mask = CAShapeLayer()
        mask.path = path.cgPath

        // Mask the image view
        imageView.layer.mask = mask

        // Add a shadow to self
        layer.shadowPath = path.cgPath

        // Add a border to self
        borderLayer.path = path.cgPath
        borderLayer.frame = bounds
    }

    private func setupBorder() {
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.separator.cgColor
        borderLayer.lineWidth = 1
        layer.addSublayer(borderLayer)
    }

    private func setupShadow() {
        layer.masksToBounds = false
        layer.shadowColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        layer.shadowOffset = CGSize(width: -1, height: 1)
        layer.shadowOpacity = 1
        layer.shadowRadius = ShadowedImageView.cornerRadius * 1.5
    }

    func resetShadow() {
        layer.shadowPath = nil
        borderLayer.path = nil
    }
}

extension UIImageView {
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
