//
//  UIApplication+Directories.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 07.07.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

extension UIApplication {
    static func cacheDirectory() -> URL {
        guard let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("Unable to get system cache directory")
        }

        return cacheURL
    }

    static func cacheDirectory(named cacheDirectoryName: String) -> URL {
        let cacheURL = UIApplication.cacheDirectory().appendingPathComponent(cacheDirectoryName)
        try? FileManager.default.createDirectory(at: cacheURL, withIntermediateDirectories: true, attributes: nil)
        return cacheURL
    }

    static func documentCreationCacheDirectory() -> URL {
        return cacheDirectory(named: ".DocumentCreation")
    }

    static func documentExportCacheDirectory() -> URL {
        return FileManager.default.temporaryDirectory
    }

    static func fileImportCacheDirectory() -> URL {
        return cacheDirectory(named: ".FileImport")
    }

    static func documentsDirectory() -> URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to get system docs directory")
        }

        return documentsURL
    }

    static func realmMirrorDirectory() -> URL {
        let mirrorDirectory = documentsDirectory().appendingPathComponent(".realm", isDirectory: true)
        try? FileManager.default.createDirectory(at: mirrorDirectory, withIntermediateDirectories: true, attributes: nil)
        return mirrorDirectory
    }

    static func clearCaches() {
        let directories = [UIApplication.documentCreationCacheDirectory(), UIApplication.fileImportCacheDirectory()]

        let paths: [URL] = directories.reduce(into: []) { acc, url in
            let files: [String] = (try? FileManager.default.contentsOfDirectory(atPath: url.path)) ?? []
            let paths = files.map { url.appendingPathComponent($0) }
            acc.append(contentsOf: paths)
        }

        paths.forEach {
            // TODO Take some action if this fails
            try? FileManager.default.removeItem(at: $0)
        }
    }
}
