//
//  ViewController.swift
//  MGRSMapKit
//
//  Created by restjohn on 10/05/2018.
//  Copyright (c) 2018 restjohn. All rights reserved.
//

import UIKit
import MapKit
import MGRSMapKit

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var zoomLabel: UILabel!
    @IBOutlet weak var zoomInButton: UIButton!
    @IBOutlet var mapTap: UITapGestureRecognizer!

    private var zoom: Double = 0.0
    private lazy var mgrsOverlay = MGRSOverlay()
    private lazy var mgrsOverlayRenderer = MGRSOverlayRenderer(overlay: mgrsOverlay)

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self

        if #available(iOS 11.0, *) {
            let scale = MKScaleView(mapView: mapView)
            scale.translatesAutoresizingMaskIntoConstraints = false
            scale.scaleVisibility = .visible
            scale.legendAlignment = .trailing
            view.addSubview(scale)
            NSLayoutConstraint.activate([
                scale.rightAnchor.constraint(equalTo: zoomInButton.rightAnchor),
                scale.bottomAnchor.constraint(equalTo: zoomInButton.topAnchor, constant: -12.0),
                scale.heightAnchor.constraint(equalToConstant: 20.0)
            ])
        }
        else {
            mapView.showsScale = true
        }

        mapView.add(mgrsOverlay, level: .aboveLabels)

        mapView.addGestureRecognizer(mapTap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return mgrsOverlayRenderer
    }

    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
//        let center = mapView.region.center
//        let span: MKCoordinateSpan = mapView.region.span
//        let rect = mapView.visibleMapRect
//        NSLog("changed region: %f %f %f %f rect: %@", center.longitude, center.latitude, span.longitudeDelta, span.latitudeDelta, MKStringFromMapRect(rect))
//        NSLog("points/lat = %f", rect.height / span.latitudeDelta)
    }

    @IBAction func mapViewTap(_ sender: UITapGestureRecognizer) {
        let tapPoint = sender.location(in: view)
        let loc = mapView.convert(tapPoint, toCoordinateFrom: view)
        let mapPoint = MKMapPointForCoordinate(loc)
        let redrawRect = MKMapRect(origin: mapPoint, size: MKMapSize(width: 100.0, height: 100.0))
        mgrsOverlayRenderer.setNeedsDisplayIn(redrawRect)
        NSLog("map point %@, loc %f %f", MKStringFromMapPoint(mapPoint), loc.longitude, loc.latitude)
    }

    @IBAction func onZoomInTapped() {
        let region = mapView.region
        let zoomed = MKCoordinateRegionMake(region.center, MKCoordinateSpanMake(region.span.latitudeDelta / 2, region.span.longitudeDelta / 2))
        mapView.setRegion(zoomed, animated: true)
    }

    @IBAction func onZoomOutTapped() {
        let region = mapView.region
        let zoomed = MKCoordinateRegionMake(region.center, MKCoordinateSpanMake(region.span.latitudeDelta * 2, region.span.longitudeDelta * 2))
        mapView.setRegion(zoomed, animated: true)
    }

    @IBAction func onRedrawTapped() {
        mgrsOverlayRenderer.setNeedsDisplay()
    }
}

