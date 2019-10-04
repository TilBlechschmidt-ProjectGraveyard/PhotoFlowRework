//
//  Dictionary+Take.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 21.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation

extension Dictionary where Key == String, Value == Any {
    func take<T>(from key: String) -> T? {
        return self[key] as? T
    }
}
