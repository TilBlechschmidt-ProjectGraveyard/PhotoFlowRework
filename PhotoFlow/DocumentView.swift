//
//  DocumentView.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 23.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import SwiftUI

struct DocumentView: View {
    var document: UIDocument
    var dismiss: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text("File Name")
                    .foregroundColor(.secondary)

                Text(document.fileURL.lastPathComponent)
            }

            Button("Done", action: dismiss)
        }
    }
}
