//
//  HorizontalListViewController.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 04.10.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import RealmSwift

class HorizontalListViewController: UICollectionViewController {
    private let document: Document
    private let realm: Realm
    private let request: AssetRequest
    private let results: Results<Asset>
    private var notificationToken: NotificationToken?
    private let selectionNotifier: SelectionNotifier
    private var selectionObserver: SelectionObserver?
    
    var selectedIndexPath: IndexPath? {
        guard let selectionIdentifier = selectionNotifier.selectionIdentifier else {
            return nil
        }
        
        return self.indexPath(for: selectionIdentifier)
    }
    
    init(document: Document, request: AssetRequest = AssetRequest(), notifier: SelectionNotifier) throws {
        self.document = document
        self.realm = try document.createRealm()

        self.request = request
        self.results = request.execute(on: realm)
        
        self.selectionNotifier = notifier
            
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal

        super.init(collectionViewLayout: layout)

        collectionView.contentInsetAdjustmentBehavior = .never

        collectionView.delegate = self
        collectionView.register(HorizontalListViewCell.self, forCellWithReuseIdentifier: "cell")

        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func indexPath(for identifier: String) -> IndexPath? {
        let index = self.results.index(matching: "rawIdentifier = %@", identifier)
        return index.map { IndexPath(item: $0, section: 0) }
    }
    
    private func refreshSelection() {
        if let previous = selectionNotifier.previousIdentifier, let indexPath = indexPath(for: previous) {
            let cell = collectionView.cellForItem(at: indexPath) as? HorizontalListViewCell
            cell?.borderShown = false
        }
        
        if let selected = selectionNotifier.selectionIdentifier, let indexPath = indexPath(for: selected) {
            let cell = collectionView.cellForItem(at: indexPath) as? HorizontalListViewCell
            cell?.borderShown = true
            
            if cell == nil, let lastVisiblePath = collectionView.indexPathsForVisibleItems.last {
                let isRightOutOfView = lastVisiblePath < indexPath
                collectionView.scrollToItem(at: indexPath, at: isRightOutOfView ? .right : .left, animated: true)
                // TODO Selection border isn't showing properly and this is a dirty workaround
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: refreshSelection)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .systemBackground
        
        self.selectionObserver = selectionNotifier.observe { [unowned self] _ in
            self.refreshSelection()
        }
        
        self.notificationToken = results.observe { [unowned self] (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                self.collectionView.reloadData()
                self.refreshSelection()
            case .update(_, let deletions, let insertions, let modifications):
                self.collectionView.performBatchUpdates({
                    self.collectionView.insertItems(at: insertions.map { IndexPath(row: $0, section: 0) })
                    self.collectionView.deleteItems(at: deletions.map { IndexPath(row: $0, section: 0) })
                    self.collectionView.reloadItems(at: modifications.map { IndexPath(row: $0, section: 0) })
                }, completion: { _ in self.refreshSelection() })
            case .error(let err):
                fatalError("\(err)")
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        refreshSelection()
        
        selectedIndexPath.map {
            collectionView.scrollToItem(at: $0, at: .centeredHorizontally, animated: false)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let asset = results[indexPath.item]

        if let cell = cell as? HorizontalListViewCell, let representation = asset.representations.filter("rawType = 1").first {
            if selectedIndexPath == indexPath {
                cell.borderShown = true
            }

            if let data = self.document.representationManager.load(representation.identifier) {
                cell.loadImage(image: data.image, asset: asset)
            }
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = results[indexPath.item]
        selectionObserver?.notifier.select(asset.rawIdentifier)
    }
}

extension HorizontalListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let defaultSize: Double = Double(view.frame.height)
        guard let metadata = results[indexPath.item].metadata else {
            return CGSize(width: defaultSize, height: defaultSize)
        }
        
        let targetHeight = defaultSize
        let targetWidth = targetHeight / metadata.height * metadata.width

        return CGSize(width: targetWidth, height: targetHeight)
    }
}

class HorizontalListViewCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let activityIndicator = UIActivityIndicatorView()
    private let acceptedIcon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
    private let rejectedIcon = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))

    fileprivate var borderShown: Bool = false {
        didSet {
            layer.borderColor = borderShown ? UIColor.systemBlue.cgColor : UIColor.clear.cgColor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.activityIndicator.startAnimating()
        borderShown = false
    }

    private func setupUI() {
        backgroundColor = .systemGray5
        layer.borderWidth = 3
        layer.borderColor = UIColor.clear.cgColor

        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        setup(icon: acceptedIcon, color: .systemGreen)
        setup(icon: rejectedIcon, color: .systemRed)
    }

    private func setup(icon: UIImageView, color: UIColor) {
        icon.alpha = 0
        icon.tintColor = color
        icon.layer.cornerRadius = 7.5
        icon.backgroundColor = .white
        addSubview(icon)
        icon.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(Constants.spacing / 2)
            make.right.equalToSuperview().inset(Constants.spacing / 2)
            make.width.equalTo(15)
            make.height.equalTo(15)
        }
    }

    func loadImage(image: UIImage?, asset: Asset) {
        imageView.alpha = 1
        acceptedIcon.alpha = 0
        rejectedIcon.alpha = 0
        
        imageView.image = image
        activityIndicator.stopAnimating()

        if asset.accepted {
            acceptedIcon.alpha = 1
        } else if asset.rejected {
            imageView.alpha = 0.15
            rejectedIcon.alpha = 0.25
        }
    }
}
