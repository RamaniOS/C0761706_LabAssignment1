//
//  ViewController.swift
//  C0761706_LabAssignment1
//
//  Created by Ramanpreet Singh on 2020-01-14.
//  Copyright © 2020 Ramanpreet Singh. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {

    // IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var stepper: UIStepper!
    
    // Varibales
    var oldValue: Double = 0
    private var userLocation: CLLocationCoordinate2D?
    private var destination: CLLocationCoordinate2D?
    private var locationManager = CLLocationManager()
    private let request = MKDirections.Request()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initViews()
    }
    
    // Initviews
    private func initViews() {
        oldValue = stepper.value
        request.transportType = .automobile
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // Check for Location Services
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
        }
        if let userLocation = locationManager.location?.coordinate {
            self.userLocation = userLocation
        }
        // Double tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapPress))
        tapGesture.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(tapGesture)
        locationManager.startUpdatingLocation()
    }
    
    // Tap gesture Recognizer
    @objc func tapPress(gestureRecognizer: UIGestureRecognizer) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        destination = nil
        let touchPoint = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.title = "Destination"
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        self.destination = coordinate
    }
    
    // Location manager delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation: CLLocation = locations[0]
        let lat = userLocation.coordinate.latitude
        let long = userLocation.coordinate.longitude
        let latDelta: CLLocationDegrees = 0.5
        let longDelta: CLLocationDegrees = 0.5
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
        let location = CLLocationCoordinate2D(latitude: lat, longitude: long)
        self.userLocation = location
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    // Get route
    func getRoute() {
        guard let currentLocation = userLocation, let destination = destination else {
            return
        }
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination, addressDictionary: nil))
        request.requestsAlternateRoutes = true
        let directions = MKDirections(request: request)
        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else {
                print(error?.localizedDescription ?? "")
                return
            }
            let route = unwrappedResponse.routes[0]
            self.mapView.addOverlay(route.polyline)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
        }
    }
    
    // Actions
    @IBAction func getRouteButtonClicked(_ sender: Any) {
        getRoute()
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        mapView.removeOverlays(mapView.overlays)
        switch sender.selectedSegmentIndex {
            case 0: // Automobile
                request.transportType = .automobile
            case 1: // Walking
                request.transportType = .walking
            default: break
        }
    }
    
    @IBAction func zoomInOut(_ sender: UIStepper) {
        if sender.value > oldValue {
            oldValue += 1
            let span = MKCoordinateSpan(latitudeDelta: mapView.region.span.latitudeDelta/2, longitudeDelta: mapView.region.span.longitudeDelta/2)
            let region = MKCoordinateRegion(center: mapView.region.center, span: span)
            mapView.setRegion(region, animated: true)
        } else {
            oldValue -= 1
            let span = MKCoordinateSpan(latitudeDelta: mapView.region.span.latitudeDelta*2, longitudeDelta: mapView.region.span.longitudeDelta*2)
            let region = MKCoordinateRegion(center: mapView.region.center, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
}

extension UIViewController: MKMapViewDelegate {
    
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.blue
        return renderer
    }
}
