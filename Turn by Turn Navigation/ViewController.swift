//
//  ViewController.swift
//  Turn by Turn Navigation
//
//  Created by Lucas Caron Albarello on 01/01/2018.
//  Copyright © 2018 Lucas Caron Albarello. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AVFoundation
class ViewController: UIViewController {

    @IBOutlet weak var directionLabel: UILabel!
    
    @IBOutlet weak var search: UISearchBar!
    
    @IBOutlet weak var mapa: MKMapView!
    
    let locationManager = CLLocationManager()
    var currentCoordinate : CLLocationCoordinate2D!
    var steps = [MKRouteStep]()
    let speechSynthesizer = AVSpeechSynthesizer()
    var stepCounter = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
    }

    func getDirections(to destination: MKMapItem){
        let sourcePlaceMark = MKPlacemark(coordinate: currentCoordinate)
        let sourceMapItem = MKMapItem(placemark: sourcePlaceMark)
        let directionRequest = MKDirectionsRequest()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destination
        directionRequest.transportType = .automobile
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let response = response else {return}
            guard let route = response.routes.first else {return}
            self.mapa.add(route.polyline)
            self.locationManager.monitoredRegions.forEach({self.locationManager.stopMonitoring(for: $0)})
            self.steps = route.steps
            for i in 0 ..< route.steps.count{
                let step = route.steps[i]
                print(step.instructions)
                print(step.distance)
                let region = CLCircularRegion(center: step.polyline.coordinate, radius: 20, identifier: "\(i)")
                self.locationManager.startMonitoring(for: region)
                let circle = MKCircle(center: region.center, radius: region.radius)
                self.mapa.add(circle)
            }
            let initialMessage = "In \(self.steps[0].distance) meters, \(self.steps[0].instructions) then in \(self.steps[1].distance) meters, \(self.steps[1].instructions)."
            self.directionLabel.text = initialMessage
            let speechUtterance = AVSpeechUtterance(string: initialMessage)
            self.speechSynthesizer.speak(speechUtterance)
            self.stepCounter += 1
        }
    }
    
}

extension ViewController : CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        guard let currentLocation = locations.first else {return}
        currentCoordinate = currentLocation.coordinate
        mapa.userTrackingMode = .followWithHeading
    }
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered")
        self.stepCounter += 1
        if stepCounter < steps.count {
            let currentStep = steps[stepCounter]
            let message = "In \(currentStep.distance) meters, \(currentStep.instructions)."
            directionLabel.text = message
            let speachUterrance = AVSpeechUtterance(string: message)
            speechSynthesizer.speak(speachUterrance)
        } else{
            let message = "Arrived at destination"
            self.directionLabel.text = message
            let speachUterrance = AVSpeechUtterance(string: message)
            speechSynthesizer.speak(speachUterrance)
            stepCounter = 0
            locationManager.monitoredRegions.forEach({self.locationManager.stopMonitoring(for: $0)})
        }
    }
}

extension ViewController : UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        let localSearchRequest = MKLocalSearchRequest()
        localSearchRequest.naturalLanguageQuery = searchBar.text
        let region = MKCoordinateRegion(center: currentCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        localSearchRequest.region = region
        let localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.start { (response, error) in
            guard let response = response else {return}
            print(response.mapItems)
            guard let firsMapItem = response.mapItems.first else {return}
            self.getDirections(to: firsMapItem)
        }
    }
}

extension ViewController : MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.lineWidth = 5
            return renderer
        }
        if overlay is MKCircle{
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.strokeColor = .red
            renderer.fillColor = .red
            renderer.alpha = 1.5
            return renderer
        }
        return MKOverlayRenderer()
    }
}
