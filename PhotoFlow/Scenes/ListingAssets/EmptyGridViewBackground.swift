//
//  EmptyGridViewBackground.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 03.12.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

class EmptyGridViewBackground: UIStackView {
    init() {
        let icon = UIImage(systemName: "camera")
        let imageView = UIImageView(image: icon)
        
        let label = UILabel()
        label.text = "Nothing here yet."
        
        super.init(frame: .zero)
        
        spacing = 16
        axis = .vertical
        alignment = .fill
        distribution = .fill
        
        addArrangedSubview(imageView)
        addArrangedSubview(label)
        
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
