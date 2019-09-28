//
//  AssetGridCell.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 24.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import SnapKit

struct Constants {
    static let spacing: CGFloat = 8
}

class AssetGridCell: UICollectionViewCell {
    var gesturesEnabled: Bool = false

    let imagesView = UIView()
    let imageView = ShadowedImageView()

    let labelView = UILabel()
    let iconView = UIImageView()

    private let leftActionItem = UIImageView()
    private let rightActionItem = UIImageView()

    let activityIndicator = UIActivityIndicatorView(style: .medium)

    let panGestureRecognizer = PanDirectionGestureRecognizer(direction: .horizontal)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        gesturesEnabled = false

        isHidden = false
        imagesView.alpha = 1

        iconView.image = nil

        imageView.image = nil

        imageView.resetShadow()

        labelView.text = nil
        activityIndicator.startAnimating()
    }

    func addImageView(_ view: ShadowedImageView, subImage: Bool = false) {
        view.contentMode = .scaleAspectFit

        imagesView.addSubview(view)
        view.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        }
    }

    func setupUI() {
        addImageView(imageView)

        labelView.textColor = .white
        labelView.font = .preferredFont(forTextStyle: .subheadline)
        labelView.textColor = .label
        labelView.textAlignment = .center

        iconView.contentMode = .scaleAspectFit

        leftActionItem.tintColor = .systemGreen
        rightActionItem.tintColor = .systemRed

        leftActionItem.image = UIImage(systemName: "checkmark.circle.fill")
        rightActionItem.image = UIImage(systemName: "xmark.circle.fill")

        leftActionItem.alpha = 0
        rightActionItem.alpha = 0

        addSubview(iconView)
        addSubview(imagesView)
        addSubview(labelView)

        iconView.snp.makeConstraints { make in
            make.right.equalTo(labelView.snp.left).inset(-Constants.spacing / 2)
            make.centerY.equalTo(labelView.snp.centerY)
            make.height.lessThanOrEqualTo(labelView.font.lineHeight)
        }

        imagesView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }

        labelView.snp.makeConstraints { make in
            make.top.equalTo(imagesView.snp.bottom).offset(Constants.spacing)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(labelView.font.lineHeight)
        }

        activityIndicator.startAnimating()
        addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(leftActionItem)
        leftActionItem.snp.makeConstraints { make in
            make.centerY.equalTo(imagesView)
            leftActionItemXConstraint = make.centerX.equalTo(imagesView).constraint
        }

        addSubview(rightActionItem)
        rightActionItem.snp.makeConstraints { make in
            make.centerY.equalTo(imagesView)
            rightActionItemXConstraint = make.centerX.equalTo(imagesView).constraint
        }

        sendSubviewToBack(leftActionItem)
        sendSubviewToBack(rightActionItem)

        panGestureRecognizer.leftActionView = leftActionItem
        panGestureRecognizer.rightActionView = rightActionItem
        panGestureRecognizer.draggableView = imagesView
        imagesView.addGestureRecognizer(panGestureRecognizer)
    }

    private var leftActionItemXConstraint: Constraint!
    private var rightActionItemXConstraint: Constraint!

    func updateImageWidth() {
        let coverImageWidth = imageView.imageBoundingRect?.size.width ?? 0
        let width = coverImageWidth
        let offset = width / 2.5

        leftActionItemXConstraint.update(offset: -offset)
        rightActionItemXConstraint.update(offset: offset)
    }
}
