//
//  MapViewModel.swift
//  kepetrovaHW7
//
//  Created by Ksenia Petrova on 31.01.2022.
//

import CoreLocation
import Foundation
import MapKit
import Pods_kepetrovaHW7
import UIKit
import YandexMapsMobile

protocol MapViewModelProtocol: class {
    func getCoordinateFrom(address: String, completion:
        @escaping (_ coordinate: CLLocationCoordinate2D?, _ error: Error?)
            -> Void)
    func build(first: String, second: String)
}

class MapViewModel: MapViewModelProtocol {
    var mapView: MapViewProtocol?
    var drivingSession: YMKDrivingSession?
    
    func getCoordinateFrom(address: String, completion:
        @escaping (_ coordinate: CLLocationCoordinate2D?, _ error: Error?)
            -> Void)
    {
        DispatchQueue.global(qos: .background).async {
            CLGeocoder().geocodeAddressString(address)
                { completion($0?.first?.location?.coordinate, $1) }
        }
    }
    
    var requestPoints: [YMKRequestPoint] = []
    func build(first: String, second: String) {
        let group = DispatchGroup()
        group.enter()
        var startpoint: YMKPoint?
        var endpoint: YMKPoint?
        getCoordinateFrom(address: first, completion: { [weak self] coords, _ in
            if let coords = coords {
                self?.requestPoints.append(YMKRequestPoint(point: YMKPoint(latitude: coords.latitude, longitude: coords.longitude), type: .waypoint, pointContext: nil))
                startpoint = YMKPoint(latitude: coords.latitude, longitude: coords.longitude)
            }
            group.leave()
        })

        group.enter()
        getCoordinateFrom(address: second, completion: { [weak self] coords, _ in
            if let coords = coords {
                endpoint = YMKPoint(latitude: coords.latitude, longitude: coords.longitude)
                self?.requestPoints.append(YMKRequestPoint(point: YMKPoint(latitude: coords.latitude, longitude: coords.longitude), type: .waypoint, pointContext: nil))
            }
            group.leave()
        })
        
        var midPoint: YMKPoint?
        
        group.notify(queue: .main) {
            DispatchQueue.main.async { [weak self] in
                midPoint = YMKPoint(latitude: (startpoint!.latitude + endpoint!.latitude)/2, longitude: (startpoint!.longitude + endpoint!.longitude)/2)
                
                let responseHandler = { (routesResponse: [YMKDrivingRoute]?, error: Error?) in
                    if let routes = routesResponse {
                        self!.mapView?.onRoutesReceived(routes)
                    } else {
                        self!.mapView?.onRoutesError(error!)
                    }
                }
                
                self?.mapView?.buildPath(requestPoints: self!.requestPoints, responseHandler: responseHandler)
                self?.mapView?.configureMap(point: midPoint!, zoom: 5)
                self?.mapView?.clean()
            }
        }
        requestPoints = []
    }
}
