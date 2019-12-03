//
//  EXIFMetadata.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 21.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import RealmSwift

enum ExposureProgram: Int {
    // Manual & Semi-manual programs
    case manual = 1
    case aperturePriority = 3
    case shutterPriority = 4

    // Fully automatic programs
    case autoNormal = 2
    case autoCreative = 5
    case autoAction = 6
    case autoPortrait = 7
    case autoLandscape = 8
}

enum ColorSpace: Int {
    case sRGB = 1
    case adobeRGB = 2
    case uncalibrated = 65535
}

@objcMembers
class EXIFMetadata: Object {
    // Other possibly interesting values: ApertureValue/MaxApertureValue, Flash, FocalPlane*, PixelXDimension, PixelYDimension, MeteringMode

    dynamic var digitizationTime: Date = Date()
    dynamic var captureTime: Date = Date()

    /// Color space the image was stored in
    let rawColorSpace = RealmOptional<Int>() // ColorSpace
//    let colorSpace: ColorSpace?

    /// Exposure bias value of taking picture. Unit is EV.
    let exposureBias = RealmOptional<Double>()

    /// Exposure program that the camera used when image was taken.
    let rawExposureProgram = RealmOptional<Int>() // ExposureProgram
//    let exposureProgram: ExposureProgram?

    /// Shutter speed. To convert this value to ordinary 'Shutter Speed' calculate this value's power of 2, then reciprocal.
    /// For example, if value is '4', shutter speed is 1/(2^4)=1/16 second. NOTE: This value seems to be inaccurate. Use exposure time instead.
    let shutterSpeed = RealmOptional<Double>()

    /// Exposure time (reciprocal of shutter speed). Unit is second.
    let exposureTime = RealmOptional<Double>()

    /// The actual F-number (F-stop) of lens when the image was taken.
    let fNumber = RealmOptional<Int>()

    /// The actual aperture value of lens when the image was taken.
    ///
    /// To convert this value to ordinary F-number(F-stop), calculate this value's power of root 2 (=1.4142).
    /// For example, if value is '5', F-number is 1.4142^5 = F5.6.
    let apertureValue = RealmOptional<Double>()

    /// Focal length of lens used to take image. Unit is millimeter.
    let focalLength = RealmOptional<Int>()

    /// CCD sensitivity equivalent to Ag-Hr film speedrate.
    let iso = RealmOptional<Int>()
}

extension EXIFMetadata {
    convenience init(from dict: [String: Any]) {
        self.init()
        
        colorSpace = dict.take(from: "ColorSpace").flatMap { ColorSpace(rawValue: $0) }
        exposureBias.value = dict.take(from: "ExposureBiasValue")
        exposureProgram = dict.take(from: "ExposureProgram").flatMap { ExposureProgram(rawValue: $0) }
        shutterSpeed.value = dict.take(from: "ShutterSpeedValue")
        exposureTime.value = dict.take(from: "ExposureTime")
        fNumber.value = dict.take(from: "FNumber")
        apertureValue.value = dict.take(from: "ApertureValue")
        focalLength.value = dict.take(from: "FocalLength")
        
        let isos: [Int]? = dict.take(from: "ISOSpeedRatings")
        iso.value = isos?.first

        let captureTime: String? = dict.take(from: "DateTimeOriginal")
        let digitizationTime: String? = dict.take(from: "DateTimeDigitized")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"

        self.captureTime = captureTime.flatMap { dateFormatter.date(from: $0) } ?? Date()
        self.digitizationTime = digitizationTime.flatMap { dateFormatter.date(from: $0) } ?? Date()
    }
}

extension EXIFMetadata {
    var colorSpace: ColorSpace? {
        get {
            return rawColorSpace.value.flatMap { ColorSpace(rawValue: $0) }
        }
        set {
            rawColorSpace.value = newValue?.rawValue
        }
    }
    
    var exposureProgram: ExposureProgram? {
        get {
            return rawExposureProgram.value.flatMap { ExposureProgram(rawValue: $0) }
        }
        set {
            rawExposureProgram.value = newValue?.rawValue
        }
    }
}

extension EXIFMetadata {
    /// Human readable exposure program
    var exposureProgramString: String? {
        guard let exposureProgram = exposureProgram else {
            return nil
        }

        switch exposureProgram {
        case .manual:
            return "Manual"
        case .aperturePriority:
            return "Aperture priority"
        case .shutterPriority:
            return "Shutter priority"
        case .autoNormal:
            return "Automatic"
        case .autoCreative:
            return "Automatic (Creative)"
        case .autoAction:
            return "Automatic (Action)"
        case .autoPortrait:
            return "Automatic (Portrait)"
        case .autoLandscape:
            return "Automatic (Landscape)"
        }
    }

    /// Human readable exposure
    var exposureString: String? {
        guard let exposureTime = exposureTime.value else {
            return nil
        }

        if exposureTime < 1 {
            return "1/\(Int(round(1/exposureTime)))"
        } else {
            return "\(exposureTime)"
        }
    }

    /// Human readable aperture
    var apertureString: String? {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        guard let fNumber = fNumber.value, let fNumberString = formatter.string(from: NSNumber(value: fNumber)) else {
            return nil
        }

        return "ƒ/\(fNumberString)"
    }

    /// Human readable ISO
    var isoString: String? {
        guard let iso = iso.value else {
            return nil
        }

        return "ISO \(iso)"
    }
}
