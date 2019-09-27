//
//  ImportFilesViewController.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 24.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import RealmSwift

protocol ImportFilesDelegate: class {
    func importFilesDidFinish(_ importFilesViewController: ImportFilesViewController)
}

enum ImportError: Error {
    case thumbnailCreationFailed
}

class ImportFilesViewController: UIViewController {
    private let document: Document
    private let documentPickerViewController: UIDocumentPickerViewController

    private let progressLabel = UILabel()
    private let progressView = UIView()

    weak var delegate: ImportFilesDelegate?

    init(document: Document) {
        self.document = document
        documentPickerViewController = UIDocumentPickerViewController(documentTypes: ["public.image"], in: .open)
        documentPickerViewController.allowsMultipleSelection = true
        documentPickerViewController.shouldShowFileExtensions = true
        super.init(nibName: nil, bundle: nil)
        documentPickerViewController.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        progressLabel.font = .preferredFont(forTextStyle: .callout)

        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.startAnimating()

        let stackView = UIStackView(arrangedSubviews: [activityIndicator, progressLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.spacing = Constants.spacing

        progressView.blur(style: .systemMaterial, cornerRadius: Constants.spacing)
        progressView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Constants.spacing * 2)
        }

        view.isUserInteractionEnabled = false
        view.addSubview(progressView)
        
        progressView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(Constants.spacing * 3)
            make.centerX.equalToSuperview()
        }

        progressView.alpha = 0
        // TODO Add shadow to progressView
    }

    func beginImport() {
        present(documentPickerViewController, animated: true, completion: nil)
    }
}

extension ImportFilesViewController: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // TODO
        delegate?.importFilesDidFinish(self)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        progressView.alpha = 1
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let realm: Realm = try self.document.createRealm()

                for (index, url) in urls.enumerated() {
                    DispatchQueue.main.async {
                        self.progressLabel.text = "Importing image \(index + 1) of \(urls.count)"
                    }
                    try autoreleasepool {
                        _ = url.startAccessingSecurityScopedResource()
                        let data = try Data(contentsOf: url)
                        url.stopAccessingSecurityScopedResource()

                        guard let thumbnailData = CGImage.thumbnail(for: data) else {
                            throw ImportError.thumbnailCreationFailed
                        }

                        let asset = Asset()
                        asset.origin = .files
                        asset.identifier = UUID()
                        asset.name = url.deletingPathExtension().lastPathComponent

                        let original = Representation()
                        original.type = .original
                        original.identifier = data.sha256String()
                        asset.representations.append(original)

                        let thumbnail = Representation()
                        thumbnail.type = .thumbnail
                        thumbnail.identifier = thumbnailData.sha256String()
                        asset.representations.append(thumbnail)

                        realm.beginWrite()
                        realm.add(asset)
                        try self.document.representationManager.store(data, for: original.identifier)
                        try self.document.representationManager.store(thumbnailData, for: thumbnail.identifier)
                        try realm.commitWrite()
                    }
                }
            } catch {
                print(error)
            }

            DispatchQueue.main.async {
                self.progressLabel.text = "Saving project"
            }

            self.document.updateChangeCount(.done)
            self.document.autosave { _ in
                DispatchQueue.main.async {
                    self.delegate?.importFilesDidFinish(self)
                }
            }
        }
    }
}
