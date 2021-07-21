//
//  MainMapViewController.swift
//  42restaurants
//
//  Created by 최강훈 on 2021/07/20.
//

import UIKit
import NMapsMap
import CoreLocation
import Firebase

class MainMapViewController: UIViewController {

    @IBOutlet weak var mapView: NMFMapView!
    
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.startUpdatingLocation() // 안해주면 위치 안 받아옴.

        return manager
    }()
    
    let userMarker = NMFMarker()

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.requestWhenInUseAuthorization()
        self.mapView.positionMode = .normal
            
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MainMapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            print("GPS 권한 설정됨")
            if let coordinate = locationManager.location?.coordinate {
                moveCameraToUserLocation(coordinate)
            }
        case .restricted, .notDetermined:
            print("GPS 권한 설정되지 않음.")
            self.locationManager.requestWhenInUseAuthorization()
        case .denied:
            print("GPS 권한 요청 거부됨")
            self.locationManager.requestWhenInUseAuthorization()
        default:
            print("GPS Default")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location: CLLocation = locations.first
        else {return}
        
        let NMGCurrentLocation =
            NMGLatLng(lat: location.coordinate.latitude,
                      lng: location.coordinate.longitude)
        
        print("location: \(NMGCurrentLocation)")
        userMarker.position = NMGCurrentLocation
        userMarker.mapView = mapView

        
        
//        let infoWindow = NMFInfoWindow()
//        let dataSource = NMFInfoWindowDefaultTextSource.data()
//        dataSource.title = "test"
//        infoWindow.dataSource = dataSource
//        infoWindow.open(with: marker)
//


    }
    
    /*
     위치를 최초로 받아올 때
     user의 위치에 맞게 카메라를 이동시키고
     user를 표시하는 marker의 속성을 지정한다.
     */
    func moveCameraToUserLocation(_ coordinate: CLLocationCoordinate2D) {
        let NMGCurrentLocation = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
        let cameraPosition = NMGCurrentLocation
        let cameraUpdate = NMFCameraUpdate(scrollTo: cameraPosition)
        mapView.moveCamera(cameraUpdate)
        
        userMarker.captionText = "ME"
        if let userLocationImage = UIImage(systemName: "circle.fill") {
            let overlayImage = NMFOverlayImage.init(image: userLocationImage)
            userMarker.iconImage = overlayImage
        }
        userMarker.iconTintColor = UIColor.systemRed

    }
}
