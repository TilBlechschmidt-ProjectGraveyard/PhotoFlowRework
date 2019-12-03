//
//  MetadataViewController.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 02.12.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import MapKit

class MetadataViewController: UIViewController {
    let histogramView = HistogramView()
    let metadataView = MetadataView()
    
    var asset: Asset? = nil { didSet { updateData() } }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(histogramView)
        view.addSubview(metadataView)
        
        histogramView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(200)
        }
        
        metadataView.snp.makeConstraints { make in
            make.top.equalTo(histogramView.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    private func updateData() {
        metadataView.resetLabels()
        
        histogramView.histogramData = asset?.metadata?.histogram
        
        // TODO Extract this to a metadata formatter
        
        let exif = asset?.metadata?.exif
        let aux = asset?.metadata?.aux
        let tiff = asset?.metadata?.tiff
        
        // MARK: Settings
        if let shutterSpeed = exif?.exposureString {
            metadataView.shutterSpeedLabel.text = shutterSpeed
        }
        
        if let aperture = exif?.apertureString {
            metadataView.apertureLabel.text = aperture
        }
        
        if let iso = exif?.isoString {
            metadataView.isoLabel.text = iso
        }
        
        if let focalLength = exif?.focalLength.value {
            metadataView.focalLengthLabel.text = "\(focalLength)mm"
        }
        
        // MARK: Gear
        if let make = tiff?.make {
            metadataView.cameraMakeLabel.text = make
        }
        
        if let model = tiff?.model {
            metadataView.cameraModelLabel.text = model
        }
        
        if let lens = aux?.lensModel {
            metadataView.lensLabel.text = lens
            // TODO Add lens serial number
        }
        
        if let exposureProgram = exif?.exposureProgramString {
            metadataView.exposureProgramLabel.text = exposureProgram
        }
        
        // MARK: File
        if let fileSize: String = nil {
            metadataView.sizeLabel.text = fileSize
        }
        
        if let fileType = asset?.humanReadableUTI {
            metadataView.fileTypeLabel.text = fileType
        }
        
        if let width = asset?.metadata?.width, let height = asset?.metadata?.height {
            metadataView.resolutionLabel.text = "\(Int(width)) x \(Int(height))"
        }
        
        // MARK: Other
        if let copyright = tiff?.copyright {
            metadataView.copyrightLabel.text = copyright
        }
        
        // MARK: Location
        if let location = asset?.metadata?.location {
            metadataView.location = location
        }
    }
}

class MetadataView: UIView {
    private let placeholder = "———"
    private let verticalStackView = UIStackView()
    
    // MARK: Settings
    let shutterSpeedLabel = UILabel()
    let apertureLabel = UILabel()
    let isoLabel = UILabel()
    let focalLengthLabel = UILabel()

    // MARK: Gear
    let cameraMakeLabel = UILabel()
    let cameraModelLabel = UILabel()
    let lensLabel = UILabel()
    let exposureProgramLabel = UILabel()

    // MARK: File
    let sizeLabel = UILabel()
    let fileTypeLabel = UILabel()
    let resolutionLabel = UILabel()

    // MARK: Other meta
    let copyrightLabel = UILabel()

    // MARK: Location
    private let mapView = MKMapView()
    private let annotation = MKPointAnnotation()
    
    var location: CLLocationCoordinate2D? = nil {
        didSet {
            if let location = location {
                annotation.coordinate = location
                mapView.addAnnotation(annotation)
                
                // TODO Determine distance by spread of neighboring images
                let camera = MKMapCamera(lookingAtCenter: location, fromDistance: 10000, pitch: 0, heading: 0)
                mapView.setCamera(camera, animated: false)
            } else {
                mapView.removeAnnotation(annotation)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        verticalStackView.alignment = .center
        verticalStackView.axis = .vertical
        verticalStackView.spacing = Constants.spacing * 2

        // Settings
        setup(label: shutterSpeedLabel)
        setup(label: apertureLabel)
        setup(label: isoLabel)
        setup(label: focalLengthLabel)

        let topInformationStackView = UIStackView(arrangedSubviews: [
            shutterSpeedLabel,
            apertureLabel,
            isoLabel,
            focalLengthLabel
        ])
        topInformationStackView.distribution = .equalSpacing
        verticalStackView.addArrangedSubview(topInformationStackView)
        topInformationStackView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(Constants.spacing * 4)
            make.right.equalToSuperview().inset(Constants.spacing * 4)
        }

        addSpacer()

        // Gear
        add(label: cameraMakeLabel, title: "Make")
        add(label: cameraModelLabel, title: "Model")
        add(label: lensLabel, title: "Lens")
        add(label: exposureProgramLabel, title: "Mode")
        addSpacer()

        // File
        add(label: sizeLabel, title: "Size")
        add(label: fileTypeLabel, title: "Format")
        add(label: resolutionLabel, title: "Resolution")
        addSpacer()

        // Other
        add(label: copyrightLabel, title: "Copyright")
        addSpacer()

        verticalStackView.setContentHuggingPriority(.required, for: .vertical)
        verticalStackView.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(verticalStackView)
        verticalStackView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview().inset(Constants.spacing * 2)
        }

        mapView.setContentHuggingPriority(.defaultLow, for: .vertical)
        mapView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        mapView.centerCoordinate = CLLocationCoordinate2D(latitude: 51.1, longitude: 10.2)
        addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.top.equalTo(verticalStackView.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        resetLabels()
    }

    private func add(label: UILabel, title: String) {
        let rowView = UIView()
        verticalStackView.addArrangedSubview(rowView)
        rowView.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }

        let titleLabel = UILabel()
        titleLabel.text = title

        titleLabel.textColor = .lightGray
        label.textColor = .white

        titleLabel.textAlignment = .right
        label.textAlignment = .left

        titleLabel.font = UIFont.systemFont(ofSize: 12)
        label.font = UIFont.systemFont(ofSize: 14)

        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping

        rowView.addSubview(titleLabel)
        rowView.addSubview(label)

        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.25)
        }

        label.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).inset(-Constants.spacing * 2)
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    private func addSpacer() {
        let spacer = UIView()
        spacer.backgroundColor = .systemGray // TODO System Border
        verticalStackView.addArrangedSubview(spacer)
        spacer.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.width.equalToSuperview()
        }
    }

    private func setup(label: UILabel) {
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
    }

    func resetLabels() {
        let labels = [
            shutterSpeedLabel,
            apertureLabel,
            isoLabel,
            focalLengthLabel,
            cameraMakeLabel,
            cameraModelLabel,
            lensLabel,
            exposureProgramLabel,
            sizeLabel,
            fileTypeLabel,
            resolutionLabel,
            copyrightLabel
        ]

        labels.forEach { $0.text = placeholder }
        location = nil
    }
}
