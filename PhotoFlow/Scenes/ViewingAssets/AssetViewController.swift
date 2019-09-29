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

    private var preloadedItems: [RepresentationData] = []

    private let representationViewController = RepresentationViewController()

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

    init?(document: Document, request: AssetRequest, asset: Asset) {
        self.document = document
        self.realm = try! document.createRealm()
        self.request = request
        self.results = request.execute(on: realm)
        self.asset = asset

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
        representationViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func updateAsset() {
        guard let data = document.representationManager.load(asset: asset, type: .original) else {
            return
        }

        self.data = data
        representationViewController.image = data.image

        preloadItems()

        title = asset.name
    }

    private func preloadItem(at index: Int) {
        if let data = document.representationManager.load(asset: results[index], type: .original) {
            preloadedItems.append(data)
        }
    }

    private func preloadItems() {
        preloadedItems.removeAll(keepingCapacity: true)

        if let previousIndex = indexChanged(by: -1) {
            preloadItem(at: previousIndex)
        }

        if let nextIndex = indexChanged(by: 1) {
            preloadItem(at: nextIndex)
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
        }
    }

    @objc func exportAsset() {
        let url = UIApplication.documentExportCacheDirectory().appendingPathComponent("\(UUID().uuidString).jpg")
        try! data.data.write(to: url)

        // TODO Use correct UTI
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
}
