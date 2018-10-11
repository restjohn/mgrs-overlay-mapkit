//
//  MGRSOverlay.swift
//  MGRSMapKit
//
//  Created by Robert St. John on 10/5/18.
//

import Foundation
import MapKit
import UIKit

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

    public override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {

        let width = 3.0 / zoomScale
        context.setLineWidth(width)

//        let tile = rect(for: mapRect)
//        context.setStrokeColor(UIColor.gray.cgColor)
//        context.beginPath()
//        context.addRect(tile)
//        context.strokePath()

        let region = MKCoordinateRegionForMapRect(mapRect)
        let halfLon = region.span.longitudeDelta / 2.0
        let left = region.center.longitude - halfLon + 180.0
        let right = region.center.longitude + halfLon + 180.0
        let zonesBefore = floor(left / 6.0)
        let mgrsColor = UIColor(red: 84.0 / 255.0, green: 131.0 / 255.0, blue: 40.0 / 255.0, alpha: 0.75).cgColor
        context.setLineCap(CGLineCap.square)
        context.setStrokeColor(mgrsColor)
        var zoneCount = Int(zonesBefore) + 1
        var zoneLon = zonesBefore * 6.0 - 180.0
        let stop = right - 180.0
        while (zoneLon <= stop) {
            let zoneCoord = CLLocationCoordinate2DMake(0.0, zoneLon)
            let zoneMapPoint = MKMapPointForCoordinate(zoneCoord)
            let zoneX = zoneMapPoint.x
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

            zoneLon += 6.0
            zoneCount += 1
        }
    }
}
