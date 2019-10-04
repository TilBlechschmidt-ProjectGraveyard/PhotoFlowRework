//
//  AssetGridViewController.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 24.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import RealmSwift

class AssetGridViewController: UICollectionViewController {
    private let document: Document
    private let realm: Realm
    private let request: AssetRequest
    private let results: Results<Asset>
    private var notificationToken: NotificationToken?
    private var selectionObserver: SelectionObserver?

    init(document: Document, request: AssetRequest = AssetRequest()) throws {
        self.document = document
        self.realm = try document.createRealm()

        self.request = request
        self.results = request.execute(on: realm)

        let layout = UICollectionViewFlowLayout()
        layout.sectionHeadersPinToVisibleBounds = true
        layout.minimumInteritemSpacing = Constants.spacing * 3
        layout.minimumLineSpacing = Constants.spacing * 3
        layout.itemSize = CGSize(width: 200, height: 200)

        super.init(collectionViewLayout: layout)

        collectionView.delegate = self
        collectionView.allowsSelection = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
        self.selectionObserver = SelectionObserver {
            if let identifier = $0, let index = self.results.index(matching: "rawIdentifier = %@", identifier) {
                self.collectionView.selectItem(at: IndexPath(item: index, section: 0), animated: true, scrollPosition: .centeredHorizontally)
            } else {
                self.collectionView.indexPathsForSelectedItems?.forEach {
                    self.collectionView.deselectItem(at: $0, animated: true)
                }
            }
        }

        self.notificationToken = results.observe { [unowned self] (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                self.collectionView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                self.collectionView.performBatchUpdates({
                    self.collectionView.insertItems(at: insertions.map { IndexPath(row: $0, section: 0) })
                    self.collectionView.deleteItems(at: deletions.map { IndexPath(row: $0, section: 0) })
                    self.collectionView.reloadItems(at: modifications.map { IndexPath(row: $0, section: 0) })
                }, completion: nil)
            case .error(let err):
                fatalError("\(err)")
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.navigationController?.delegate = self
    }

    func setupUI() {
        collectionView.backgroundColor = .secondarySystemBackground
        collectionView.register(AssetGridCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.contentInsetAdjustmentBehavior = .always
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let asset = results[indexPath.item]

        if let cell = cell as? AssetGridCell, let representation = asset.representations.filter("rawType = 1").first {
            let representationIdentifier = representation.identifier
            cell.labelView.text = asset.name

            if asset.rejected {
                cell.imagesView.alpha = 0.15
                cell.iconView.image = UIImage(systemName: "xmark.circle.fill")
                cell.iconView.tintColor = .separator
            } else if asset.accepted {
                cell.iconView.image = UIImage(systemName: "checkmark.circle.fill")
                cell.iconView.tintColor = .systemGreen
            }

            // TODO Abort this when the cell is reused!
            // TODO Figure out why this causes issues
//            DispatchQueue.global(qos: .userInitiated).async {
                if let data = self.document.representationManager.load(representationIdentifier) {
                    DispatchQueue.main.async {
                        cell.imageView.image = data.image
                        cell.activityIndicator.stopAnimating()
                        cell.updateImageWidth()
                        cell.gesturesEnabled = true
                    }
                }
//            }

            cell.panGestureRecognizer.onSuccessfulSwipe = { [unowned self] right in
                if right {
                    try? asset.accept(realm: self.realm)
                } else {
                    try? asset.reject(realm: self.realm)
                }
            }
        }

        return cell
    }

    private var selectedFrame: CGRect?
    private var selectedImage: UIImage?
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = results[indexPath.item]
        selectionObserver?.notifier.select(asset.rawIdentifier)

        // TODO Show loading indicator
        guard let cell = collectionView.cellForItem(at: indexPath) as? AssetGridCell,
            let thumbnailData = document.representationManager.load(asset: asset, type: .thumbnail)
        else {
            return
        }

        let bounds = cell.imageView.imageBoundingRect
        selectedFrame = bounds.map { cell.imageView.convert($0, to: collectionView.superview) }
        selectedImage = thumbnailData.image

        guard let assetViewController = try? AssetViewController(document: document, request: request, asset: asset) else {
            return
        }

        parent?.navigationController?.pushViewController(assetViewController, animated: true)
    }
}

extension AssetGridViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 2 * Constants.spacing, left: 4 * Constants.spacing, bottom: 2 * Constants.spacing, right: 4 * Constants.spacing)
    }
}

extension AssetGridViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let frame = self.selectedFrame else { return nil }
        guard let image = self.selectedImage else { return nil }

        switch operation {
        case .push:
            return AssetGridAnimator(duration: TimeInterval(UINavigationController.hideShowBarDuration), isPresenting: true, originFrame: frame, image: image)
        default:
            return AssetGridAnimator(duration: TimeInterval(UINavigationController.hideShowBarDuration), isPresenting: false, originFrame: frame, image: image)
        }
    }
}
