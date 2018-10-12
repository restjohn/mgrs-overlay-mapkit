//
//  MGRSOverlay.swift
//  MGRSMapKit
//
//  Created by Robert St. John on 10/5/18.
//

import Foundation
import MapKit
import UIKit
import GEOTRANSUtil

public class MGRSOverlay : NSObject, MKOverlay {

    public let boundingMapRect: MKMapRect = MKMapRectWorld
    public let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0.0, 0.0)

    public func canReplaceMapContent() -> Bool {
        return false
    }

    public func intersects(_ mapRect: MKMapRect) -> Bool {
        return true
    }
}

public class MGRSOverlayRenderer : MKOverlayRenderer {

    static let mgrsColor = UIColor(red: 84.0 / 255.0, green: 131.0 / 255.0, blue: 40.0 / 255.0, alpha: 0.75).cgColor
    static let utmZoneWidthMapPoints = MKMapRectWorld.width / 60.0

    private let mgrs = MSPMGRSHelper()

    class func gridResolutionsFor(scale: MKZoomScale) {

    }

    public override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {

        let scaledLineWidth = 3.0 / Double(zoomScale)
        context.setLineWidth(CGFloat(scaledLineWidth))

//        let tile = rect(for: mapRect)
//        context.setStrokeColor(UIColor.gray.cgColor)
//        context.beginPath()
//        context.addRect(tile)
//        context.strokePath()

        let zonesBefore = floor(mapRect.minX / MGRSOverlayRenderer.utmZoneWidthMapPoints)

        context.setLineCap(CGLineCap.square)
        context.setStrokeColor(MGRSOverlayRenderer.mgrsColor)
        var zoneCount = Int(zonesBefore) + 1
        var zoneX = zonesBefore * MGRSOverlayRenderer.utmZoneWidthMapPoints
        while (zoneX <= mapRect.maxX + scaledLineWidth) {
            let start = point(for: MKMapPoint(x: zoneX, y: mapRect.minY))
            let end = point(for: MKMapPoint(x: zoneX, y: mapRect.maxY))
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()

            context.saveGState()
            context.setTextDrawingMode(.fill)
            context.textMatrix = CGAffineTransform(translationX: 5.0, y: 5.0)
            context.translateBy(x: start.x, y: end.y)
            context.scaleBy(x: 1.0 / zoomScale, y: -1.0 / zoomScale)
            let zoneStr = String(format: "%02d", zoneCount) as CFString
            let attrs: [CFString: Any] = [
                kCTForegroundColorAttributeName: UIColor(red: 84.0 / 255.0, green: 131.0 / 255.0, blue: 40.0 / 255.0, alpha: 1.0).cgColor,
                kCTFontAttributeName: CTFontCreateWithName("Helvetica" as CFString, 24.0, nil),
            ]
            let zoneLabel = CFAttributedStringCreate(kCFAllocatorDefault, zoneStr, attrs as CFDictionary)
            let line = CTLineCreateWithAttributedString(zoneLabel!)
            CTLineDraw(line, context)
            context.restoreGState()

            zoneX += MGRSOverlayRenderer.utmZoneWidthMapPoints
            zoneCount += 1
        }
    }
}
