//
//  DocumentBrowserViewController.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 23.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import SwiftUI

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    private let selectionNotifier: SelectionNotifier
    
    init(notifier: SelectionNotifier) {
        self.selectionNotifier = notifier
        super.init(forOpeningFilesWithContentTypes: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
        
        // Update the style of the UIDocumentBrowserViewController
        // browserUserInterfaceStyle = .dark
        // view.tintColor = .white
        
        // Specify the allowed content types of your application via the Info.plist.
        
        // Do any additional setup after loading the view.
    }
    
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        let counter = UserDefaults.standard.integer(forKey: "newCreationCounter") + 1
        UserDefaults.standard.set(counter + 1, forKey: "newCreationCounter")

        let name = "UntitledProject #\(counter)"
        let cacheDirectory = UIApplication.documentCreationCacheDirectory()
        let newDocumentURL = cacheDirectory.appendingPathComponent("\(name).photoflow")

        UIApplication.clearCaches()

        let document = Document(fileURL: newDocumentURL)

        document.save(to: newDocumentURL, for: .forCreating) {
            guard $0 else {
                importHandler(nil, .none)
                return
            }

            document.close {
                guard $0 else {
                    importHandler(nil, .none)
                    return
                }

                importHandler(newDocumentURL, .move)
            }
        }
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        presentDocument(at: sourceURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
    // MARK: Document Presentation
    
    func presentDocument(at documentURL: URL) {
        let document = Document(fileURL: documentURL)

        // Access the document
        document.open(completionHandler: { success in
            if success {
                let documentViewController = DocumentViewController(document: document, notifier: self.selectionNotifier)
                let navigationController = UINavigationController(rootViewController: documentViewController)
                navigationController.modalPresentationStyle = .currentContext
                self.present(navigationController, animated: true, completion: nil)
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
    }

    func closeDocument(_ document: Document) {
        dismiss(animated: true) {
            document.close(completionHandler: nil)
        }
    }
}

