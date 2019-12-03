//
//  ShareViewController.swift
//  PhotoFlow-ShareExtension
//
//  Created by Til Blechschmidt on 27.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import MobileCoreServices

@objc(ShareViewController)
class ShareViewController: UIViewController {
    private let documentPickerVC = UIDocumentPickerViewController(documentTypes: ["de.blechschmidt.photoflowproject"], in: .open)

    private var imageURLs: [URL] = []

    override func viewDidLoad() {
        documentPickerVC.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.global().async {
            self.imageURLs = self.imageURLsFromExtensionContext()

            guard !self.imageURLs.isEmpty else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error loading image", message: "Unable to receive image from share panel.")
                }
                return
            }

            DispatchQueue.main.async {
                self.present(self.documentPickerVC, animated: true, completion: nil)
            }
        }
    }

    func imageURLsFromExtensionContext() -> [URL] {
        let inputItems = self.extensionContext!.inputItems as! [NSExtensionItem]

        let providers = inputItems.flatMap { item in
            return (item.attachments ?? []).filter { provider in
                return provider.hasItemConformingToTypeIdentifier(kUTTypeImage as String)
            }
        }

        let imageURLs: [URL] = providers.compactMap {
            let semaphore = DispatchSemaphore(value: 0)
            var imageURL: URL? = nil

            $0.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil, completionHandler: { url, error in
                imageURL = url as? URL
                semaphore.signal()
            })

            semaphore.wait()

            return imageURL
        }

        return imageURLs
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { _ in
            alert.dismiss(animated: true)
            self.completeRequest()
        }))

        present(alert, animated: true)
    }

    func completeRequest() {
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
}

extension ShareViewController: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        self.completeRequest()
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            showAlert(title: "No project received", message: "Document picker didn't return any documents.")
            return
        }

        let document = Document(fileURL: url)
        document.open {
            guard $0 else {
                self.showAlert(title: "Failed to import", message: "An error occurred while opening the document")
                return
            }

            self.imageURLs.forEach {
                do {
                    try document.assetManager.store(from: $0, origin: .shareExtension)
                } catch {
                    print(error)
                }
            }

            document.close {
                guard $0 else {
                    self.showAlert(title: "Failed to import", message: "An error occurred while saving the document")
                    return
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.completeRequest()
        })
    }
}
