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

func mapRectForCoords(westLon: CLLocationDegrees, eastLon: CLLocationDegrees, southLat: CLLocationDegrees,  northLat: CLLocationDegrees) -> MKMapRect {
    let nw = MKMapPoint(CLLocationCoordinate2D(latitude: northLat, longitude: westLon))
    let se = MKMapPoint(CLLocationCoordinate2D(latitude: southLat, longitude: eastLon))
    return MKMapRect(x: nw.x, y: nw.y, width: se.x - nw.x, height: se.y - nw.y)
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
    static let utmLatRange = -80.0..<84.0
    static let utmYRange = yRangeForLatRange(utmLatRange)
    static let utmZoneWidthMapPoints = MKMapRect.world.width / 60.0
    static let utmZoneBoundaryExceptionYRange = yRangeForLatRange(56.0..<84.0)
    static let utmZoneBoundaryExceptions: [Int:[UTMZoneBoundarySegment]] = {
        return [
            31: [
                UTMZoneBoundarySegment(zone: 31, atLon: 0.0, fromNorthLat: utmLatRange.upperBound, toSouthLat: 56.0),
                UTMZoneBoundarySegment(zone: 32, startLon: 6.0, startLat: 64.0, endLon: 3.0, endLat: 64.0),
                UTMZoneBoundarySegment(zone: 32, startLon: 3.0, startLat: 64.0, endLon: 3.0, endLat: 56.0),
                UTMZoneBoundarySegment(zone: 32, startLon: 3.0, startLat: 56.0, endLon: 6.0, endLat: 56.0)
            ],
            32: [
                UTMZoneBoundarySegment(zone: 33, atLon: 9.0, fromNorthLat: utmLatRange.upperBound, toSouthLat: 72.0),
                UTMZoneBoundarySegment(zone: 32, atLat: 72.0, fromWestLon: 6.0, toEastLon: 12.0),
                UTMZoneBoundarySegment(zone: 32, atLon: 6.0, fromNorthLat: 72.0, toSouthLat: 64.0)
            ],
            33: [
                UTMZoneBoundarySegment(zone: 33, atLon: 12.0, fromNorthLat: 72.0, toSouthLat: 56.0)
            ],
            34: [
                UTMZoneBoundarySegment(zone: 35, atLon: 21.0, fromNorthLat: utmLatRange.upperBound, toSouthLat: 72.0),
                UTMZoneBoundarySegment(zone: 34, atLat: 72.0, fromWestLon: 18.0, toEastLon: 24.0),
                UTMZoneBoundarySegment(zone: 34, atLon: 18.0, fromNorthLat: 72.0, toSouthLat: 56.0)
            ],
            35: [
                UTMZoneBoundarySegment(zone: 35, atLon: 24.0, fromNorthLat: 72.0, toSouthLat: 56.0)
            ],
            36: [
                UTMZoneBoundarySegment(zone: 37, atLon: 33.0, fromNorthLat: utmLatRange.upperBound, toSouthLat: 72.0),
                UTMZoneBoundarySegment(zone: 36, atLat: 72.0, fromWestLon: 30.0, toEastLon:36.0),
                UTMZoneBoundarySegment(zone: 36, atLon: 30.0, fromNorthLat: 72.0, toSouthLat: 56.0)
            ],
            37: [
                UTMZoneBoundarySegment(zone: 37, atLon: 36.0, fromNorthLat: 72.0, toSouthLat: 56.0)
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
        let rectWithLine = MKMapRect(x: max(0, mapRect.origin.x - scaledLineWidth), y: mapRect.origin.y, width: mapRect.width + scaledLineWidth, height: mapRect.height)
        context.setLineWidth(CGFloat(scaledLineWidth))
        context.setLineCap(CGLineCap.square)
        context.setStrokeColor(MGRSOverlayRenderer.mgrsColor)
        context.setTextDrawingMode(.fill)

        let segments = utmZoneBoundariesIn(mapRect: rectWithLine)
        segments.forEach { segment in
            let start = point(for: segment.start)
            let end = point(for: segment.end)
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()
            if (start.y == end.y) {
                return
            }
            context.saveGState()
            context.textMatrix = CGAffineTransform(translationX: 5.0, y: 5.0)
            context.translateBy(x: start.x, y: end.y)
            context.scaleBy(x: 1.0 / zoomScale, y: -1.0 / zoomScale)
            let zoneStr = String(format: "%02d", segment.zone) as CFString
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
        let zoneX = MKMapUnit(zone - 1) * MGRSOverlayRenderer.utmZoneWidthMapPoints
        var zoneXRange = zoneX..<zoneX + MGRSOverlayRenderer.utmZoneWidthMapPoints
        let rectXRange = mapRect.minX...mapRect.maxX
        let rectYRange = mapRect.minY...mapRect.maxY
        var bounds: [UTMZoneBoundarySegment] = []
        while (zoneXRange.overlaps(rectXRange) && zone > 0) {
            if (MGRSOverlayRenderer.utmZoneBoundaryExceptionYRange.overlaps(rectYRange) &&
                MGRSOverlayRenderer.utmZoneBoundaryExceptions.contains { k, _ in k == zone }) {
                var segments: [UTMZoneBoundarySegment] = []
                let exceptions = MGRSOverlayRenderer.utmZoneBoundaryExceptions[zone]!
                exceptions.forEach { (segment) in
                    if (rectYRange.overlaps(segment.start.y...segment.end.y) && segment.zone > 0) {
                        segments.append(segment)
                    }
                }
                if (mapRect.maxY >= MGRSOverlayRenderer.utmZoneBoundaryExceptionYRange.upperBound) {
                    segments.append(UTMZoneBoundarySegment(zone: zone, x: zoneXRange.lowerBound,
                        yRange: MGRSOverlayRenderer.utmZoneBoundaryExceptionYRange.upperBound..<mapRect.maxY))
                }
                bounds.append(contentsOf: segments)
            }
            else if (MGRSOverlayRenderer.utmYRange.overlaps(rectYRange) && rectXRange.contains(zoneXRange.lowerBound)) {
                bounds.append(UTMZoneBoundarySegment(zone: zone, x: zoneXRange.lowerBound,
                    yRange: max(mapRect.minY, MGRSOverlayRenderer.utmYRange.lowerBound)..<min(mapRect.maxY, MGRSOverlayRenderer.utmYRange.upperBound)))
            }
            zoneXRange = zoneXRange.lowerBound - MGRSOverlayRenderer.utmZoneWidthMapPoints..<(zoneXRange.lowerBound)
            zone -= 1
        }
        return bounds
    }

    struct UTMZoneBoundarySegment {

        init(zone: Int, x: MKMapUnit, yRange: Range<MKMapUnit>) {
            self.zone = zone
            self.start = MKMapPoint(x: x, y: yRange.lowerBound)
            self.end = MKMapPoint(x: x, y: yRange.upperBound)
        }

        init(zone: Int, gapLatNorth: CLLocationDegrees, gapLatSouth: CLLocationDegrees) {
            self.init(zone: -abs(zone), atLon: 0.0, fromNorthLat: gapLatNorth, toSouthLat: gapLatSouth)
        }

        init(zone: Int, atLon: CLLocationDegrees, fromNorthLat: CLLocationDegrees, toSouthLat: CLLocationDegrees) {
            self.init(zone: zone, startLon: atLon, startLat: fromNorthLat, endLon: atLon, endLat: toSouthLat)
        }

        init(zone: Int, atLat: CLLocationDegrees, fromWestLon: CLLocationDegrees, toEastLon: CLLocationDegrees) {
            self.init(zone: zone, startLon: fromWestLon, startLat: atLat, endLon: toEastLon, endLat: atLat)
        }

        init(zone: Int, startLon: CLLocationDegrees, startLat: CLLocationDegrees, endLon: CLLocationDegrees, endLat: CLLocationDegrees) {
            self.zone = zone
            self.start = MKMapPoint(CLLocationCoordinate2D(latitude: startLat, longitude: startLon))
            self.end = MKMapPoint(CLLocationCoordinate2D(latitude: endLat, longitude: endLon))
        }

        let zone: Int
        let start: MKMapPoint
        let end: MKMapPoint
    }
}
