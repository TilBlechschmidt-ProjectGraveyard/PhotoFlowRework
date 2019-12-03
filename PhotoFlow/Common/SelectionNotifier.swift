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
    
    init(notifier: SelectionNotifier, closure: @escaping (String?) -> Void) {
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
    var selectionIdentifier: String? = nil
    var previousIdentifier: String? = nil
    
    func select(_ identifier: String?) {
        previousIdentifier = selectionIdentifier
        selectionIdentifier = identifier
        NotificationCenter.default.post(name: .didUpdateSelection, object: self)
    }
    
    func observe(closure: @escaping (String?) -> Void) -> SelectionObserver {
        return SelectionObserver(notifier: self, closure: closure)
    }
}

extension Notification.Name {
    static let didUpdateSelection = Notification.Name("didUpdateSelection")
}
