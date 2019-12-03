//
//  HistogramView.swift
//  PhotoFlow
//
//  Created by Til Blechschmidt on 02.12.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit

enum SettingsHistogramType: String {
    case luminance
    case rgb
}

struct HistogramMode: OptionSet {
    let rawValue: Int

    static let red       = HistogramMode(rawValue: 1 << 0)
    static let green     = HistogramMode(rawValue: 1 << 1)
    static let blue      = HistogramMode(rawValue: 1 << 2)
    static let luminance = HistogramMode(rawValue: 1 << 3)

    static let rgb: HistogramMode = [.red, .green, .blue]

    var humanReadable: String {
        var result = ""

        if contains(.red) {
            result += "R"
        }

        if contains(.green) {
            result += "G"
        }

        if contains(.blue) {
            result += "B"
        }

        if contains(.luminance) {
            result += "L"
        }

        return result
    }

    static func from(settingsType: SettingsHistogramType) -> HistogramMode {
        switch settingsType {
        case .luminance:
            return .luminance
        case .rgb:
            return .rgb
        }
    }
}

class HistogramView: UIView {
    var histogramData: NormalizedHistogram? = nil { didSet { self.setNeedsDisplay() } }
    var colored: Bool = true { didSet { self.setNeedsDisplay() } }
    var yScaling: CGFloat = 0.9 { didSet { self.setNeedsDisplay() } }

    var mode: HistogramMode {
        didSet {
            updateModeLabel()
            self.setNeedsDisplay()
        }
    }

    private var modeLabel = UILabel()

    override init(frame: CGRect) {
        mode = HistogramMode.from(settingsType: .rgb)

        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground

        modeLabel.textColor = .lightGray
        modeLabel.font = UIFont.systemFont(ofSize: 10)
        addSubview(modeLabel)
        modeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Constants.spacing)
            make.left.equalToSuperview().inset(Constants.spacing)
        }
        updateModeLabel()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(cycleMode))
        addGestureRecognizer(tapGestureRecognizer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateModeLabel() {
        modeLabel.text = mode.humanReadable
    }

    @objc func cycleMode() {
        if mode == .rgb {
            mode = .luminance
        } else if mode == .luminance {
            mode = .rgb
        }
    }

    override open func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let histogramData = histogramData else {
            return
        }

        // Lines
        if mode.contains(.red) { draw(bins: histogramData.red, color: .red, fill: false) }
        if mode.contains(.green) { draw(bins: histogramData.green, color: .green, fill: false) }
        if mode.contains(.blue) { draw(bins: histogramData.blue, color: .blue, fill: false) }

        // Fills
        if mode.contains(.luminance) { draw(bins: histogramData.luminance, color: .white) }
        if mode.contains(.red) { draw(bins: histogramData.red, color: #colorLiteral(red: 0.7843137255, green: 0.1960784314, blue: 0.1960784314, alpha: 1)) }
        if mode.contains(.green) { draw(bins: histogramData.green, color: #colorLiteral(red: 0.1960784314, green: 0.7843137255, blue: 0.1960784314, alpha: 1)) }
        if mode.contains(.blue) { draw(bins: histogramData.blue, color: #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.7843137255, alpha: 1)) }
    }

    private func draw(bins: [CGFloat], color: UIColor, fill: Bool = true) {
        let path = UIBezierPath()

        if colored {
            color.setFill()
            color.setStroke()
        } else {
            UIColor.white.setFill()
        }

        let yAxisHeight = self.bounds.height
        let xAxisWidth = self.bounds.width

        let scaleY: (CGFloat) -> CGFloat = {
            return yAxisHeight - $0 * yAxisHeight * self.yScaling
        }

        let binCount: CGFloat = 256
        let binWidth = xAxisWidth / binCount

        // Move to origin
        let origin = CGPoint(x: 0, y: yAxisHeight)
        path.move(to: origin)

        // Iterate points
        bins.enumerated().forEach {
            let (offset, value) = $0
            path.addLine(to: CGPoint(x: CGFloat(offset) * binWidth, y: scaleY(value)))
        }

        if fill {
            path.addLine(to: CGPoint(x: xAxisWidth, y: yAxisHeight))
            path.addLine(to: origin)
            path.fill(with: CGBlendMode.plusLighter, alpha: 1)
        } else {
            // TODO Strokes should only be on the top not behind other areas. Fix it.
            path.stroke()
        }
    }
}
