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
    private var selectionObserver: SelectionObserver?
    
    init(document: Document, request: AssetRequest = AssetRequest()) throws {
        self.document = document
        self.realm = try document.createRealm()

        self.request = request
        self.results = request.execute(on: realm)
            
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
    
    private func refreshSelection() {
        self.refreshSelection(of: selectionObserver?.notifier.selectionIdentifier)
    }
    
    private func refreshSelection(of identifier: String?) {
        if let identifier = identifier, let index = self.results.index(matching: "rawIdentifier = %@", identifier) {
            self.collectionView.selectItem(at: IndexPath(item: index, section: 0), animated: true, scrollPosition: .centeredHorizontally)
        } else {
            self.collectionView.indexPathsForSelectedItems?.forEach {
                self.collectionView.deselectItem(at: $0, animated: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        self.selectionObserver = SelectionObserver {
            self.refreshSelection(of: $0)
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
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let asset = results[indexPath.item]

        if let cell = cell as? HorizontalListViewCell, let representation = asset.representations.filter("rawType = 1").first {
            cell.isSelected = false
            
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
        return 5
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

    override var isSelected: Bool {
        didSet {
            layer.borderColor = isSelected ? UIColor.white.cgColor : UIColor.clear.cgColor
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
    }

    private func setupUI() {
        layer.borderWidth = 2

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
