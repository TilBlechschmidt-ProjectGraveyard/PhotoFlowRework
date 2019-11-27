//
//  AssetViewController.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 24.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import CoreImage
import RealmSwift

class AssetViewController: UIViewController {
    private var fullscreen = false
    private var shareController: UIDocumentInteractionController?

    private let document: Document
    private let realm: Realm
    private let request: AssetRequest
    private let results: Results<Asset>
    private var asset: Asset { didSet { updateAsset() } }
    private var data: RepresentationData!
    
    private var selectionObserver: SelectionObserver?

    private var preloadedItems: [RepresentationData] = []

    private let representationViewController = RepresentationViewController()
    private let horizontalListViewController: HorizontalListViewController

    private lazy var rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(exportAsset))

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return fullscreen
    }

    override var navigationItem: UINavigationItem {
        let item = super.navigationItem
        item.rightBarButtonItem = rightBarButtonItem
        return item
    }

    init?(document: Document, request: AssetRequest, asset: Asset) throws {
        self.document = document
        self.realm = try document.createRealm()
        self.request = request
        self.results = request.execute(on: realm)
        self.asset = asset
        
        self.horizontalListViewController = try HorizontalListViewController(document: document, request: request)

        super.init(nibName: nil, bundle: nil)

        updateAsset()

        representationViewController.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        add(representationViewController)
        add(horizontalListViewController)
        
        representationViewController.view.snp.makeConstraints { make in
            make.top.equalTo(horizontalListViewController.view.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        horizontalListViewController.view.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(75)
        }
        
        selectionObserver = SelectionObserver { [unowned self] in
            guard let identifier = $0, let asset = self.results.filter("rawIdentifier = %@", identifier).first else { return }
            self.asset = asset
        }
    }

    private func updateAsset() {
        guard let data = document.representationManager.load(asset: asset, type: .original) else {
            return
        }

        self.data = data
        representationViewController.representationData = data

        preloadItems()

        title = asset.name
    }

    private func preloadItem(with id: String) {
        // TODO This causes a lot of issues
//        if let data = document.representationManager.load(id) {
//            preloadedItems.append(data)
//        }
    }

    private func preloadItems() {
        
        let previousID = indexChanged(by: -1).flatMap {
            return document.representationManager.representationID(for: results[$0], type: .original)
        }
        
        let nextID = indexChanged(by: 1).flatMap {
            return document.representationManager.representationID(for: results[$0], type: .original)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Remove all items but keep them in memory until the next caching has been completed
            var cacheClear = self.preloadedItems
            defer { cacheClear.removeAll() }
            self.preloadedItems.removeAll(keepingCapacity: true)

            if let previousID = previousID {
                self.preloadItem(with: previousID)
            }

            if let nextID = nextID {
                self.preloadItem(with: nextID)
            }
        }
    }

    private func indexChanged(by delta: Int) -> Int? {
        guard let currentIndex = results.firstIndex(of: asset) else {
            return nil
        }

        let nextIndex = currentIndex + delta

        if nextIndex < 0 {
            return nil
        }

        if nextIndex >= results.count {
            return nil
        }

        return nextIndex
    }

    private func changeIndex(by delta: Int) {
        if let newIndex = indexChanged(by: delta) {
            self.asset = results[newIndex]
            self.selectionObserver?.notifier.select(self.asset.rawIdentifier)
        }
    }

    @objc func exportAsset() {
        let url = UIApplication.documentExportCacheDirectory()
            .appendingPathComponent("\(asset.name)-exported")
            .appendingPathExtension(asset.fileExtension)
        
        try! data.data.write(to: url)

        shareController = UIDocumentInteractionController(url: url)
        shareController?.uti = asset.uti
        shareController?.presentOpenInMenu(from: rightBarButtonItem, animated: false)

        // TODO Add delegate and remove temporary item after transfer
    }
}

extension AssetViewController: RepresentationViewControllerDelegate {
    func representationViewControllerDidAcceptAsset() {
        try! asset.accept(realm: realm)
    }

    func representationViewControllerDidRejectAsset() {
        try! asset.reject(realm: realm)
    }

    func representationViewControllerSwipedForward() {
        changeIndex(by: 1)
    }

    func representationViewControllerSwipedBackwards() {
        changeIndex(by: -1)
    }
    
    func representationViewControllerSwipedDownwards() {
        navigationController?.popViewController(animated: true)
    }
}
