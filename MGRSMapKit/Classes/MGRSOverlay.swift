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

typealias MKMapUnit = Double
typealias GeoCoord = CLLocationCoordinate2D

func xForLon(_ lonDegrees: CLLocationDegrees) -> MKMapUnit {
    return MKMapPoint(CLLocationCoordinate2D(latitude: 0.0, longitude: lonDegrees)).x
}

func yForLat(_ latDegrees: CLLocationDegrees) -> MKMapUnit {
    return MKMapPoint(CLLocationCoordinate2D(latitude: latDegrees, longitude: 0.0)).y
}

func yRangeForLatRange(_ latRange: Range<CLLocationDegrees>) -> Range<MKMapUnit> {
    let yMin = yForLat(latRange.upperBound)
    let yMax = yForLat(latRange.lowerBound)
    return yMin..<yMax
}

public class MGRSOverlay : NSObject, MKOverlay {

    public let boundingMapRect: MKMapRect = MKMapRect.world
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
    static let utmZoneWidthMapPoints = MKMapRect.world.width / 60.0
    static let utmZoneBoundaryExceptionYRange = yRangeForLatRange(56.0..<90.0)
    static let utmZoneBoundaryExceptions: [Int:[UTMZoneBoundarySegment]] = {
        return [
            31: [
                UTMZoneBoundarySegment(normalZone: 31, exceptionZone: 32, xMin: xForLon(3.0), yRange: yRangeForLatRange(56.0..<64.0))
            ],
            32: [
                UTMZoneBoundarySegment(normalZone: 32, exceptionZone: 32, xMin: xForLon(6.0), yRange: yRangeForLatRange(56.0..<64.0)),
                UTMZoneBoundarySegment(normalZone: 32, exceptionZone: 33, xMin: xForLon(9.0), yRange: yRangeForLatRange(72.0..<84.0))
            ],
            33: [
                UTMZoneBoundarySegment(normalZone: 33, exceptionZone: 33, xMin: xForLon(12.0), yRange: yRangeForLatRange(72.0..<84.0))
            ],
            34: [
                UTMZoneBoundarySegment(normalZone: 34, exceptionZone: 34, xMin: xForLon(18.0), yRange: yRangeForLatRange(72.0..<84.0)),
                UTMZoneBoundarySegment(normalZone: 34, exceptionZone: 35, xMin: xForLon(21.0), yRange: yRangeForLatRange(72.0..<84.0))
            ],
            35: [
                UTMZoneBoundarySegment(normalZone: 35, exceptionZone: 35, xMin: xForLon(24.0), yRange: yRangeForLatRange(72.0..<84.0))
            ],
            36: [
                UTMZoneBoundarySegment(normalZone: 36, exceptionZone: 36, xMin: xForLon(30.0), yRange: yRangeForLatRange(72.0..<84.0)),
                UTMZoneBoundarySegment(normalZone: 36, exceptionZone: 37, xMin: xForLon(33.0), yRange: yRangeForLatRange(72.0..<84.0))
            ],
            37: [
                UTMZoneBoundarySegment(normalZone: 37, exceptionZone: 37, xMin: xForLon(36.0), yRange: yRangeForLatRange(72.0..<84.0))
            ]
        ]
    }()

    private let mgrs = MSPMGRSHelper()

    public override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
//        let region = MKCoordinateRegion(mapRect)
//        let sw = CLLocationCoordinate2D(latitude: region.center.latitude - region.span.latitudeDelta / 2.0, longitude: region.center.longitude - region.span.longitudeDelta / 2.0)
//        let ne = CLLocationCoordinate2D(latitude: region.center.latitude + region.span.latitudeDelta / 2.0, longitude: region.center.longitude + region.span.longitudeDelta / 2.0)
//        NSLog("render region %f %f  to %f %f", sw.longitude, sw.latitude, ne.longitude, ne.latitude)

        var scaledLineWidth = 1.0 / Double(zoomScale)

        context.setLineWidth(CGFloat(scaledLineWidth))

        let tile = rect(for: mapRect)
        context.setStrokeColor(UIColor.black.cgColor)
        context.beginPath()
        context.addRect(tile)
        context.strokePath()

        scaledLineWidth = 5.0 / Double(zoomScale)
        let rectWithLine = MKMapRect(x: mapRect.origin.x, y: mapRect.origin.y, width: mapRect.width + 2 * scaledLineWidth, height: mapRect.height)
        context.setLineWidth(CGFloat(scaledLineWidth))
        context.setLineCap(CGLineCap.square)
        context.setStrokeColor(MGRSOverlayRenderer.mgrsColor)

        let zoneBoundaries = utmZoneBoundariesIn(mapRect: rectWithLine)
        zoneBoundaries.forEach { zoneBoundary in
            if (zoneBoundary.isGapInNormalZone()) {
                return
            }
            let start = point(for: MKMapPoint(x: zoneBoundary.xMin, y: zoneBoundary.yRange.lowerBound))
            let end = point(for: MKMapPoint(x: zoneBoundary.xMin, y: zoneBoundary.yRange.upperBound))
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()
            context.saveGState()
            context.setTextDrawingMode(.fill)
            context.textMatrix = CGAffineTransform(translationX: 5.0, y: 5.0)
            context.translateBy(x: start.x, y: end.y)
            context.scaleBy(x: 1.0 / zoomScale, y: -1.0 / zoomScale)
            let zoneStr = String(format: "%02d", zoneBoundary.normalZone) as CFString
            let attrs: [CFString: Any] = [
                kCTForegroundColorAttributeName: UIColor(red: 84.0 / 255.0, green: 131.0 / 255.0, blue: 40.0 / 255.0, alpha: 1.0).cgColor,
                kCTFontAttributeName: CTFontCreateWithName("Helvetica" as CFString, 24.0, nil),
                ]
            let zoneLabel = CFAttributedStringCreate(kCFAllocatorDefault, zoneStr, attrs as CFDictionary)
            let line = CTLineCreateWithAttributedString(zoneLabel!)
            CTLineDraw(line, context)
            context.restoreGState()
        }
    }

    func utmZoneBoundariesIn(mapRect: MKMapRect) -> [UTMZoneBoundarySegment] {
        var zone = Int(floor(mapRect.maxX / MGRSOverlayRenderer.utmZoneWidthMapPoints)) + 1
        var zoneX = MKMapUnit(zone - 1) * MGRSOverlayRenderer.utmZoneWidthMapPoints
        var bounds: [UTMZoneBoundarySegment] = []
        while (zoneX >= mapRect.minX && zone > 0) {
            if (MGRSOverlayRenderer.utmZoneBoundaryExceptionYRange.overlaps(mapRect.minY...mapRect.maxY) &&
                MGRSOverlayRenderer.utmZoneBoundaryExceptions.contains { k, _ in k == zone }) {
                let exceptionBoundaries = MGRSOverlayRenderer.utmZoneBoundaryExceptions[zone]
            }
            else {
                bounds.append(UTMZoneBoundarySegment(normalZone: zone, exceptionZone: nil, xMin: zoneX, yRange: mapRect.minY..<mapRect.maxY))
            }
            zoneX -= MGRSOverlayRenderer.utmZoneWidthMapPoints
            zone -= 1
        }
        return bounds
    }
}

struct UTMZoneBoundarySegment {

    let normalZone: Int
    let exceptionZone: Int?
    let xMin: MKMapUnit
    let yRange: Range<MKMapUnit>

    func isExceptionBoundary() -> Bool {
        return exceptionZone != nil
    }

    func isGapInNormalZone() -> Bool {
        return normalZone == exceptionZone
    }
}
