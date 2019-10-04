//
//  CGImage+Histogram.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 24.05.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import CoreGraphics
import Accelerate

struct NormalizedHistogram {
    let red: [CGFloat]
    let green: [CGFloat]
    let blue: [CGFloat]
    let luminance: [CGFloat]
    
    init(red: [CGFloat] = Array(repeating: 0, count: 256),
         green: [CGFloat] = Array(repeating: 0, count: 256),
         blue: [CGFloat] = Array(repeating: 0, count: 256),
         luminance: [CGFloat] = Array(repeating: 0, count: 256)
    ) {
        self.red = red
        self.green = green
        self.blue = blue
        self.luminance = luminance
    }
    
    func encode() -> Data {
        let combinedBins = red + green + blue + luminance
        let bytes = combinedBins.flatMap { $0.bytes }
        return Data(bytes)
    }
    
    static func decode(_ data: Data) -> Self? {
        var data = data
        var combinedBins: ArraySlice<CGFloat> = []
        let size = MemoryLayout<CGFloat>.size
        
        while data.count >= size {
            combinedBins.append(CGFloat(bytes: Array(data.prefix(upTo: size)))!)
            
            if data.count <= size {
                break
            }
            
            data = data.advanced(by: size)
        }
        
        guard combinedBins.count == 256 * 4 else { return nil }
        
        let red = combinedBins[0..<256]
        let green = combinedBins[256..<(256 * 2)]
        let blue = combinedBins[(256 * 2)..<(256 * 3)]
        let luminance = combinedBins[(256 * 3)...]
        
        return NormalizedHistogram(red: Array(red), green: Array(green), blue: Array(blue), luminance: Array(luminance))
    }
}

extension CGImage {
    // TODO Return luminance bin as well.
    // Algorithm for luminance described at the end of page 2 in the following document:
    // https://www.itu.int/dms_pubrec/itu-r/rec/bt/R-REC-BT.601-7-201103-I!!PDF-E.pdf
    func calculateNormalizedHistogram() -> NormalizedHistogram {
        let (_, red, green, blue) = calculateHistogram()

        var luminance: [CGFloat] = Array(repeating: 0.0, count: red.count)
        for i in 0..<red.count {
            luminance[i] = 0.299 * CGFloat(red[i]) + 0.587 * CGFloat(green[i]) + 0.114 * CGFloat(blue[i])
        }

        let maximumLuminanceCount = luminance.max() ?? 0
        let maximumLuminanceValue = CGFloat(maximumLuminanceCount)
        let normalizedLuminance = luminance.map { $0 / maximumLuminanceValue }

        let maximumPixelCount = (red + green + blue).max() ?? 0
        let maximumValue = CGFloat(maximumPixelCount)
        let normalize: ([UInt]) -> [CGFloat] = { $0.map { CGFloat($0) / maximumValue } }

        return NormalizedHistogram(
            red: normalize(red),
            green: normalize(green),
            blue: normalize(blue),
            luminance: normalizedLuminance
        )
    }

    func calculateHistogram() -> (alpha: [UInt], red: [UInt], green: [UInt], blue: [UInt]) {
        var inBuffer = vImage_Buffer()

        var format = vImage_CGImageFormat(bitsPerComponent: 8,
                                          bitsPerPixel: 32,
                                          colorSpace: nil,
                                          bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
                                          version: 0,
                                          decode: nil,
                                          renderingIntent: .defaultIntent)

        let bufferError = vImageBuffer_InitWithCGImage(&inBuffer, &format, nil, self, vImage_Flags(kvImageNoFlags))

        guard bufferError == kvImageNoError else {
            // TODO Remove fatalError
            fatalError("Buffer error.")
        }

        let alpha = [UInt](repeating: 0, count: 256)
        let red = [UInt](repeating: 0, count: 256)
        let green = [UInt](repeating: 0, count: 256)
        let blue = [UInt](repeating: 0, count: 256)

        let alphaPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: alpha) as UnsafeMutablePointer<vImagePixelCount>?
        let redPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: red) as UnsafeMutablePointer<vImagePixelCount>?
        let greenPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: green) as UnsafeMutablePointer<vImagePixelCount>?
        let bluePtr = UnsafeMutablePointer<vImagePixelCount>(mutating: blue) as UnsafeMutablePointer<vImagePixelCount>?

        let argb = [alphaPtr, redPtr, greenPtr, bluePtr]

        let histogram = UnsafeMutablePointer<UnsafeMutablePointer<vImagePixelCount>?>(mutating: argb)
        let histogramError = vImageHistogramCalculation_ARGB8888(&inBuffer, histogram, UInt32(kvImageNoFlags))

        guard histogramError == kvImageNoError else {
            // TODO Remove fatalError
            fatalError("Histogram error.")
        }

        free(inBuffer.data)

        return (alpha: alpha, red: red, green: green, blue: blue)
    }
}
