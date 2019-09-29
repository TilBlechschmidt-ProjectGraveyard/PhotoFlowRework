//
//  DocumentViewController.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 23.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import SnapKit

class DocumentViewController: UIViewController {
    private let document: Document

    override var navigationItem: UINavigationItem {
        let item = super.navigationItem

        item.largeTitleDisplayMode = .never
        item.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeDocument))
        item.rightBarButtonItems = [
            UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(startImport))
        ]

        return item
    }

    init(document: Document) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
        self.title = document.title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let gridViewController = try! AssetGridViewController(document: document)
        add(gridViewController)

        gridViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc func closeDocument() {
        // Show progress indicator
        document.close { success in
            // TODO Error handling
            self.dismiss(animated: true, completion: nil)
        }
    }

    @objc func startImport() {
        let importViewController = ImportFilesViewController(document: document)
        importViewController.delegate = self

        addChild(importViewController)

        view.addSubview(importViewController.view)
        importViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        importViewController.didMove(toParent: self)
        importViewController.beginImport()
    }
}

extension DocumentViewController: ImportFilesDelegate {
    func importFilesDidFinish(_ importFilesViewController: ImportFilesViewController) {
        importFilesViewController.removeFromParent()
        importFilesViewController.view.removeFromSuperview()
        importFilesViewController.didMove(toParent: nil)
    }
}
