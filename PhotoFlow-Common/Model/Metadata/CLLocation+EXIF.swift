//
//  CLLocation+EXIF.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 21.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import CoreLocation

extension CLLocationCoordinate2D {
    init?(from exifDict: [String: Any]) {
        guard let latitude: Double = exifDict.take(from: "Latitude"), let longitude: Double = exifDict.take(from: "Longitude") else {
            return nil
        }

        // TODO Take the following values into account:
        // LatitudeRef = N
        // LongitudeRef = E

        // Do so by flipping values when:
        // LatitudeRef = S
        // LongitudeRef = W

        self.init(latitude: latitude, longitude: longitude)
    }
}
