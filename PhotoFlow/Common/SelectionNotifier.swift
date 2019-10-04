//
//  SelectionNotifier.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 04.10.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation

class SelectionObserver {
    let closure: (_ identifier: String?) -> Void
    let notifier: SelectionNotifier
    
    init(notifier: SelectionNotifier = SelectionNotifier.shared, closure: @escaping (String?) -> Void) {
        self.notifier = notifier
        self.closure = closure
        NotificationCenter.default.addObserver(self, selector: #selector(notify), name: .didUpdateSelection, object: notifier)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func notify(_ notification: Notification) {
        if let notifier = notification.object as? SelectionNotifier {
            closure(notifier.selectionIdentifier)
        }
    }
}

class SelectionNotifier {
    static let shared = SelectionNotifier()
    
    var selectionIdentifier: String? = nil
    
    func select(_ identifier: String?) {
        selectionIdentifier = identifier
        NotificationCenter.default.post(name: .didUpdateSelection, object: self)
    }
}

extension Notification.Name {
    static let didUpdateSelection = Notification.Name("didUpdateSelection")
}
