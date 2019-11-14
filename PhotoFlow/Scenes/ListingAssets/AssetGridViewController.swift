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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.navigationController?.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
        self.selectionObserver = SelectionObserver { [unowned self] in
            self.updateSelection(withIdentifier: $0)
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

    func setupUI() {
        collectionView.backgroundColor = .secondarySystemBackground
        collectionView.register(AssetGridCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.contentInsetAdjustmentBehavior = .always
    }
    
    func updateSelection(withIdentifier identifier: String?, animated: Bool = true) {
        (0..<self.results.count).forEach { index in
            let indexPath = IndexPath(item: index, section: 0)
            let cell = self.collectionView.cellForItem(at: indexPath) as? AssetGridCell
            cell?.shadowedImageView.imageView.tag = -1
        }
        
        if let identifier = identifier, let index = self.results.index(matching: "rawIdentifier = %@", identifier) {
            let indexPath = IndexPath(item: index, section: 0)
            
            let cell = self.collectionView.cellForItem(at: indexPath) as? AssetGridCell
            cell?.shadowedImageView.imageView.tag = AssetGridAnimator.tag
            
            self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: animated)
        }
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
                cell.shadowedImageView.alpha = 0.15
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
                        cell.shadowedImageView.image = data.image
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

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = results[indexPath.item]
        selectionObserver?.notifier.select(asset.rawIdentifier)

        guard let assetViewController = try? AssetViewController(document: document, request: request, asset: asset) else {
            return
        }

        parent?.navigationController?.pushViewController(assetViewController, animated: true)
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension AssetGridViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 2 * Constants.spacing, left: 4 * Constants.spacing, bottom: 2 * Constants.spacing, right: 4 * Constants.spacing)
    }
}

extension AssetGridViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        guard let imageView = collectionView.viewWithTag(AssetGridAnimator.tag) as? UIImageView, let image = imageView.image else {
            return nil
        }

        let duration = TimeInterval(UINavigationController.hideShowBarDuration)
        switch operation {
        case .push:
            return AssetGridAnimator(duration: duration, isPresenting: true, image: image)
        default:
            return AssetGridAnimator(duration: duration, isPresenting: false, image: image)
        }
    }
}
