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
//    private let activityIndicator = UIActivityIndicatorView(style: .large)
//    private let label = UILabel()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        label.text = "Importing photo"
//
//        let stackView = UIStackView(arrangedSubviews: [label, activityIndicator])
//        stackView.axis = .vertical
//        stackView.alignment = .center
//        stackView.distribution = .equalCentering
//        view.addSubview(stackView)
//        stackView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
//    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.global().async {
            self.imageURLFromExtensionContext() { url in
                if let url = url {
                    let filename = url.lastPathComponent
                    print(filename, url.path)

                    DispatchQueue.main.async {
                        self.showAlert(title: "Import successful", message: "Image was added to its source project.")
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Error loading image", message: "Unable to receive image from share panel.")
                    }
                }
            }
        }
    }

    func imageURLFromExtensionContext(completionHandler: @escaping (URL?) -> ()) {
        for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
            for provider in item.attachments! {
                if provider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                    provider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil, completionHandler: { (imageURL, error) in
                        if let imageURL = imageURL as? URL {
                            completionHandler(imageURL)
                        } else {
                            completionHandler(nil)
                        }
                    })
                    break
                }
            }
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { _ in
            alert.dismiss(animated: true)
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        }))

        present(alert, animated: true)
    }
}
