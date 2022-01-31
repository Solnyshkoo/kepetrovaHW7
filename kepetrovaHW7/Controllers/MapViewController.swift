//
//  ViewController.swift
//  kepetrovaHW7
//
//  Created by Ksenia Petrova on 30.01.2022.
//

import CoreLocation
import Foundation
import MapKit
import Pods_kepetrovaHW7
import UIKit
import YandexMapsMobile

protocol MapViewProtocol: class {
    func configureMap(point: YMKPoint, zoom: Int)
    func onRoutesReceived(_ routes: [YMKDrivingRoute])
    func onRoutesError(_ error: Error)
    func buildPath(requestPoints: [YMKRequestPoint], responseHandler: @escaping ([YMKDrivingRoute]?, Error?) -> Void)
    func clean()
}

final class MapViewController: UIViewController {
    // MARK: - Properties

    private let locationManager = CLLocationManager()
    var mapModel: MapViewModelProtocol?
    private let mapView: YMKMapView = {
        let mapView = YMKMapView()
        mapView.layer.masksToBounds = true
        mapView.layer.cornerRadius = 5
        mapView.clipsToBounds = false
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.scalesLargeContentImage = true
        mapView.mapWindow.map.isRotateGesturesEnabled = false
        mapView.mapWindow.map.move(
            with: YMKCameraPosition(target: YMKPoint(latitude: 59.945933, longitude: 30.320045), zoom: 15, azimuth: 0, tilt: 0),
            animationType: YMKAnimation(type: YMKAnimationType.smooth, duration: 5),
            cameraCallback: nil)
        return mapView
    }()

    private let buildButton: CustomButtons = {
        let button = CustomButtons(backColor: .systemBlue, textColor: .white, text: "Build")
        button.addTarget(self, action: #selector(goButtonWasPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let clearButton: CustomButtons = {
        let button = CustomButtons(backColor: .systemMint, textColor: .white, text: "Clear")
        button.addTarget(self, action: #selector(clearButtonWasPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let startLocation: CustomTextField = {
        let control = CustomTextField(text: "From")
        return control
    }()

    private let endLocation: CustomTextField = {
        let control = CustomTextField(text: "To")
        return control
    }()

    private let textStack: UIStackView = {
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 10
        return textStack
    }()

    // MARK: - life cicle

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupMapView()
        configureUI()
        setupButtons()
    }

    func setup() {
        let viewContr = self
        let model = MapViewModel()
        viewContr.mapModel = model
        model.mapView = viewContr
    }

    @objc func clearButtonWasPressed() {
        startLocation.text = nil
        endLocation.text = nil
        startLocation.placeholder = "From"
        endLocation.placeholder = "To"
        clearButton.active(status: false)
        buildButton.active(status: false)
        clean()
    }

    @objc func goButtonWasPressed() {
        guard
            let first = startLocation.text,
            let second = endLocation.text,
            first != second
        else {
            return
        }
        mapModel!.build(first: first, second: second)
    }

    var drivingSession: YMKDrivingSession?

    func buildPath(requestPoints: [YMKRequestPoint], responseHandler: @escaping ([YMKDrivingRoute]?, Error?) -> Void) {
        let drivingRouter = YMKDirections.sharedInstance().createDrivingRouter()
        drivingSession = drivingRouter.requestRoutes(
            with: requestPoints,
            drivingOptions: YMKDrivingDrivingOptions(),
            vehicleOptions: YMKDrivingVehicleOptions(),
            routeHandler: responseHandler)
    }

    // MARK: - setupMapView

    func setupMapView() {
        view.addSubview(mapView)

        mapView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        mapView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true

        let scale = UIScreen.main.scale
        let mapKit = YMKMapKit.sharedInstance()
        let userLocationLayer = mapKit.createUserLocationLayer(with: mapView.mapWindow)

        userLocationLayer.setVisibleWithOn(true)
        userLocationLayer.isHeadingEnabled = true
        userLocationLayer.setAnchorWithAnchorNormal(
            CGPoint(x: 0.5 * mapView.frame.size.width * scale, y: 0.5 * mapView.frame.size.height * scale),
            anchorCourse: CGPoint(x: 0.5 * mapView.frame.size.width * scale, y: 0.83 * mapView.frame.size.height * scale))
        userLocationLayer.setObjectListenerWith(self)
    }

    func setupButtons() {
        let stackView = UIStackView(arrangedSubviews: [buildButton, clearButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            stackView.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    private func configureUI() {
        view.addSubview(textStack)
        textStack.pin(to: view, [.top: 60, .left: 10, .right: 10])
        [startLocation, endLocation].forEach { textField in
            textField.setHeight(to: 40)
            textField.delegate = self
            textStack.addArrangedSubview(textField)
        }
    }
}

// MARK: - MapViewProtocol

extension MapViewController: MapViewProtocol {
    func configureMap(point: YMKPoint, zoom: Int) {
        // view.addSubview(mapView)
        mapView.frame = view.frame
        mapView.mapWindow.map.move(
            with: YMKCameraPosition(target: point, zoom: Float(zoom), azimuth: 0, tilt: 0),
            animationType: YMKAnimation(type: YMKAnimationType.smooth, duration: 5),
            cameraCallback: nil)
    }

    func clean() {
        mapView.mapWindow.map.mapObjects.clear()
    }

    func onRoutesReceived(_ routes: [YMKDrivingRoute]) {
        let mapObjects = mapView.mapWindow.map.mapObjects
        for route in routes {
            mapObjects.addPolyline(with: route.geometry)
        }
    }

    func onRoutesError(_ error: Error) {
        let routingError = (error as NSError).userInfo[YRTUnderlyingErrorKey] as! YRTError
        var errorMessage = "Unknown error"
        if routingError.isKind(of: YRTNetworkError.self) {
            errorMessage = "Network error"
        } else if routingError.isKind(of: YRTRemoteError.self) {
            errorMessage = "Remote server error"
        }

        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        present(alert, animated: true, completion: nil)
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay)
        render.strokeColor = .blue
        render.lineWidth = 10
        print("addd")
        return render
    }
}

// MARK: - UITextFieldDelegate

extension MapViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        startLocation.resignFirstResponder()
        endLocation.resignFirstResponder()
        view.endEditing(true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let startText = startLocation.text?.replacingOccurrences(of: " ", with: "")
        let endText = endLocation.text?.replacingOccurrences(of: " ", with: "")
        if (startText != nil && startText != "") || (endText != nil && endText != "") {
            clearButton.active(status: true)
            if startText != nil, startText != "", endText != nil, endText != "" {
                buildButton.active(status: true)
            } else {
                buildButton.active(status: false)
            }
        } else {
            clearButton.active(status: false)
            buildButton.active(status: false)
        }
    }
}

// MARK: - YMKUserLocationObjectListener

extension MapViewController: YMKUserLocationObjectListener {
    func onObjectAdded(with view: YMKUserLocationView) {
        view.arrow.setIconWith(UIImage(systemName: "location")!)
        view.accuracyCircle.fillColor = UIColor.blue
    }

    func onObjectRemoved(with view: YMKUserLocationView) {}

    func onObjectUpdated(with view: YMKUserLocationView, event: YMKObjectEvent) {}
}

// MARK: - CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation])
    {
        guard let coord: CLLocationCoordinate2D =
            manager.location?.coordinate else { return }
        mapView.mapWindow.map.move(
            with: YMKCameraPosition(target: YMKPoint(latitude: coord.latitude, longitude: coord.longitude), zoom: 15, azimuth: 0, tilt: 0),
            animationType: YMKAnimation(type: YMKAnimationType.smooth, duration: 5),
            cameraCallback: nil)
    }
}
