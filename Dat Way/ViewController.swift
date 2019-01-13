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
        currentHeading = newHeading.magneticHeading
        headingLabel.text = "Magnetic heading is: \(currentHeading)"
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation: CLLocation = locations[locations.count - 1]
    
        currentLocation = lastLocation
        currentLatitude = lastLocation.coordinate.latitude
        currentLongitude = lastLocation.coordinate.longitude
        
        latitudeLabel.text = "Your current latitude is: \(currentLatitude!)"
        longitudeLabel.text = "Your current longitude is: \(currentLongitude!)"
    }
    
    
    
    @IBAction func updateDistance(_ sender: Any) {
        distance = Double(distanceField.text!)!
            distanceLabel.text = "Your distance is \(distance!)"
        let matchedStats = resultsArDistanceBearing(ar: matchedItems)
        //print(matchedItems)
        //print(matchedStats)
        //print(currentHeading)
        //print(isValidPOIAr(ar: matchedStats))
        latLong(location: matchedStats[0]["location"] as! CLLocation, name: matchedStats[0]["name"] as! String)
    }
    
    // math functions -----
    
    func someQuadrant(bearing: Double) -> String {
        
        var quadrant = bearing / 45
        
        if bearing < 0 {
            quadrant = (bearing + 360) / 45
        } else {
            quadrant = bearing / 45
        }
        
        let which_quadrant = quadrant.rounded(.up)
        
        if which_quadrant == 0 {
            return "Quadrant 1"
            
        } else {
            let string_quadrant = String(which_quadrant)
            let message = "Quadrant " + string_quadrant
            return message
        }
    }
    
    // returns the bearing of a POI relative to the user
    
    
    
    func degreesToRadians(degrees: Double) -> Double { return degrees * .pi / 180.0 }
    func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / .pi }
    
    func getBearingBetweenTwoPoints(point1 : CLLocation, point2 : CLLocation) -> Double {
        
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
    
    func haversineDistance(lat2:Double, lon2:Double) -> Double {
        
        var dist = sin(degreesToRadians(degrees: currentLatitude)) * sin(degreesToRadians(degrees: lat2)) + cos(degreesToRadians(degrees: currentLatitude)) * cos(degreesToRadians(degrees: lat2)) * cos(degreesToRadians(degrees: currentLongitude - lon2))
            
        dist = acos(dist)
        dist = radiansToDegrees(radians: dist)
        dist = dist * 60 * 1.1515
        dist = dist * 1.609344
        return dist
    }

    
    func resultsArDistanceBearing (ar: [[String:Any]]) -> [[String:Any]] {
        var matchedStats: [[String:Any]] = []
        for POI in ar {
            
            let POIBearing = getBearingBetweenTwoPoints(point1: currentLocation, point2: POI["location"] as! CLLocation)
            let POIQuadrant = someQuadrant(bearing: POIBearing)
            
            let POIStats = ["name": POI["name"]!,
                               "latitude": POI["latitude"]!,
                               "longitude": POI["longitude"]!,
                               "location": POI["location"]!,
                               "distance": haversineDistance(lat2: POI["latitude"] as! Double, lon2: POI["longitude"] as! Double),
                               "quadrant": POIQuadrant]
            
            matchedStats.append(POIStats as [String : Any])
        }
        return matchedStats
        
    }
    
    // is the POI in the correct sector and in the specified distance?
    
    // distance_of_poi is from the Haversine formula
    // user_quadrant is from somequadrant
    // user_distance is the user's input
    // quadrant_of_poi is found by founding the angle between the two points and classifying what quadrant it's in
    
    func isValidPOI(POIQuadrant: String, distance_of_poi: Double) -> Bool {
        let userQuadrant = someQuadrant(bearing: currentHeading!)
        if distance_of_poi <= distance && userQuadrant == POIQuadrant {
            return true
        } else {
            return false
        }

    }
    
    func isValidPOIAr(ar: [[String:Any]]) -> [[String:Any]] {
        var validPOIs: [[String:Any]] = []
        for POI in ar {
            if isValidPOI(POIQuadrant: POI["quadrant"] as! String, distance_of_poi: POI["distance"] as! Double) == true {
                validPOIs.append(POI)
            } else {
                continue
            }
        }
        return validPOIs
    }
    
    func latLong(location: CLLocation, name: String!)  {
        
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            
            print("Response GeoLocation : \(placemarks)")
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]
            
            // Country
            if let country = placeMark.addressDictionary!["Country"] as? String {
                print("Country :- \(country)")
                // City
                if let city = placeMark.addressDictionary!["City"] as? String {
                    print("City :- \(city)")
                    // State
                    if let state = placeMark.addressDictionary!["State"] as? String{
                        print("State :- \(state)")
                        // Street
                        if let street = placeMark.addressDictionary!["Street"] as? String{
                            print("Street :- \(street)")
                            let str = street
                            let streetNumber = str.components(
                                separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
                            print("streetNumber :- \(streetNumber)" as Any)
                            
                            // ZIP
                            if let zip = placeMark.addressDictionary!["ZIP"] as? String{
                                print("ZIP :- \(zip)")
                                // Location name
                                if let locationName = name {
                                    print("Location Name :- \(locationName)")
                                    // Street address
                                    if let thoroughfare = placeMark?.addressDictionary!["Thoroughfare"] as? NSString {
                                        print("Thoroughfare :- \(thoroughfare)")
                                        
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
    
}

extension ViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
}
