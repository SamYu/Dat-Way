//
//  ViewController.swift
//  Dat Way
//
//  Created by Tony Wang on 2019-01-12.
//  Copyright © 2019 Tony Wang. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Foundation
import Darwin

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    

    @IBOutlet weak var myMapView: MKMapView!
    @IBOutlet weak var searchText: UITextField!
    @IBOutlet weak var distanceField: UITextField!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    
    @IBAction func textFieldReturn(_ sender: UITextField) {
        _ = sender.resignFirstResponder()
        myMapView.removeAnnotations(myMapView.annotations)
        self.performSearch()
    }
    
    var matchingItems: [MKMapItem] = [MKMapItem()]
    var matchedItems: [[String:Any]] = []
    
    var lm:CLLocationManager!
    var currentLatitude: Double!
    var currentLongitude: Double!
    var currentLocation: CLLocation!
    var currentHeading: CLLocationDirection!
    var distance: Double!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lm = CLLocationManager()
        lm.requestWhenInUseAuthorization()
        lm.headingOrientation = .portrait
        lm.headingFilter = kCLHeadingFilterNone
        lm.delegate = self
        lm.startUpdatingLocation()
        lm.startUpdatingHeading()
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText.text
        request.region = myMapView.region
        
        
        
        let search = MKLocalSearch(request: request)
        
        search.start(completionHandler: {(response, error) in
            
            if error != nil
            {
                print ("ERROR")
            }
            else if response!.mapItems.count == 0
            {
                print ("Not Found")
            }
            else
            {
                for items in response!.mapItems
                {
                    print ("Name=\(String(describing: items.name))")
                    print ("Latitude=\(String(describing: items.placemark.location?.coordinate.latitude))")
                    print ("Longitude=\(String(describing: items.placemark.location?.coordinate.longitude))")
                    
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = items.placemark.coordinate
                    annotation.title = items.name
                    annotation.subtitle = items.phoneNumber
                    self.myMapView.addAnnotation(annotation)
                    
                }
            }
            
            
        })
        
    }
    
    
    
    func performSearch() {
        
        matchingItems.removeAll()
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText.text
        request.region = myMapView.region
        
        let search = MKLocalSearch(request: request)
        
        search.start(completionHandler: {(response, error) in
            
            if let results = response {
                
                if let err = error {
                    print("Error occurred in search: \(err.localizedDescription)")
                } else if results.mapItems.count == 0 {
                    print("No matches found")
                } else {
                    print("Matches found")
                    
                    
                    
                    for item in results.mapItems {
                        
                        let resultsAr: [String:Any] =
                            ["name": item.name ?? "No match",
                             "latitude": item.placemark.location!.coordinate.latitude,
                             "longitude": item.placemark.location!.coordinate.longitude,
                             "location":
                                item.placemark.location!]
                    
                        
                        
                        self.matchingItems.append(item as MKMapItem)
                        
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = item.placemark.coordinate
                        annotation.title = item.name
                        self.myMapView.addAnnotation(annotation)
                        
                        self.matchedItems.append(resultsAr)
                    }
                    print(self.matchedItems)
                }
            }
            
        })
    }
    
    
    func locationManager(_manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed: \(error)")
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let currentHeading = newHeading.magneticHeading
        headingLabel.text = "Magnetic heading is: \(currentHeading)"
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation: CLLocation = locations[locations.count - 1]
        
        currentLatitude = lastLocation.coordinate.latitude
        currentLongitude = lastLocation.coordinate.longitude
        
        latitudeLabel.text = "Your current latitude is: \(currentLatitude!)"
        longitudeLabel.text = "Your current longitude is: \(currentLongitude!)"
    }
    
    
    
    @IBAction func updateDistance(_ sender: Any) {
        distance = Double(distanceField.text!)!
            distanceLabel.text = "Your distance is \(distance)"
    }
    
    // math functions -----
    
    func somequadrant(bearing: Double) -> String {
        let quadrant = bearing / 45
        let  which_quadrant = quadrant.rounded(.up)
        let  string_quadrant = String(which_quadrant)
        let  message = "Quadrant " + string_quadrant
        return message
    }
    
    // returns the bearing of a POI relative to the user
    
    
    
    func degreesToRadians(degrees: Double) -> Double { return degrees * .pi / 180.0 }
    func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / .pi }
    
    func getBearingBetweenTwoPoints1(point1 : CLLocation, point2 : CLLocation) -> Double {
        
        let lat1 = degreesToRadians(degrees: point1.coordinate.latitude)
        let lon1 = degreesToRadians(degrees: point1.coordinate.longitude)
        
        let lat2 = degreesToRadians(degrees: point2.coordinate.latitude)
        let lon2 = degreesToRadians(degrees: point2.coordinate.longitude)
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return radiansToDegrees(radians: radiansBearing)
    }
    
    func haversineDistance(la2: Double, lo2: Double) -> Double {
        
        let radius = 6367444.7
        
        let haversin = { (angle: Double) -> Double in
            return (1 - cos(angle))/2
        }
        
        let ahaversin = { (angle: Double) -> Double in
            return 2*asin(sqrt(angle))
        }
        
        // Converts from degrees to radians
        let dToR = { (angle: Double) -> Double in
            return (angle / 360.0) * 2.0 * .pi
        }
        
        let lat1 = dToR(currentLatitude)
        let lon1 = dToR(currentLongitude)
        let lat2 = dToR(la2)
        let lon2 = dToR(lo2)
        
        return radius * ahaversin(haversin(lat2 - lat1) + cos(lat1) * cos(lat2) * haversin(lon2 - lon1))
    }
    
    
    // is the POI in the correct sector and in the specified distance?
    
    // distance_of_poi is from the Haversine formula
    // user_quadrant is from somequadrant
    // user_distance is the user's input
    // quadrant_of_poi is found by founding the angle between the two points and classifying what quadrant it's in
    
    func isValidPOI(user_distance: Double, user_quadrant: String, quadrant_of_poi: String, distance_of_poi: Double) -> Bool {
        if distance_of_poi <= user_distance && quadrant_of_poi == user_quadrant {
            return true
        } else {
            return false
        }

    }
    
}

extension ViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
}
