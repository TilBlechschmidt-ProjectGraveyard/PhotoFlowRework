import Cocoa
import CoreGraphics

func split(_ range: Range<CGFloat>, intoIntervalsOfSize chunkWidth: CGFloat) -> [Range<CGFloat>] {
    var i: CGFloat = 0
    var intervals: [Range<CGFloat>] = []
    
    while i < range.upperBound {
        let nextI = min(i + chunkWidth, range.upperBound)
        intervals.append(i..<nextI)
        i = nextI
    }
    
    return intervals
}

func tile(size: CGSize, intoTilesOfSize tileSize: CGSize) -> [CGRect] {
    let xIntervals = split(0..<size.width, intoIntervalsOfSize: tileSize.width)
    let yIntervals = split(0..<size.height, intoIntervalsOfSize: tileSize.height)
    
    var tiles: [CGRect] = []
    
    for xInterval in xIntervals {
        for yInterval in yIntervals {
            let width = xInterval.upperBound - xInterval.lowerBound
            let height = yInterval.upperBound - yInterval.lowerBound
            tiles.append(CGRect(x: xInterval.lowerBound, y: yInterval.lowerBound, width: width, height: height))
        }
    }
    
    return tiles
}

let tiles = tile(size: CGSize(width: 11, height: 11), intoTilesOfSize: CGSize(width: 20, height: 20))
for i in tiles {
    print(i)
}
