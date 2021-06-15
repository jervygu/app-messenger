//
//  LocationPickerViewController.swift
//  Messenger
//
//  Created by Jervy Umandap on 6/14/21.
//

import UIKit
import CoreLocation
import MapKit

class LocationPickerViewController: UIViewController {
    
    public var completion: ((CLLocationCoordinate2D) -> Void)?
    
    private var coordinates: CLLocationCoordinate2D?
    
    private var isPickable = true
    
    private let map: MKMapView = {
        let map = MKMapView()
        
        return map
    }()
    
    private let buttonContainer: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        view.isHidden = true
        
        return view
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
//        button.setBackgroundImage(UIImage(systemName: "papaerplane.fill"), for: .normal)
        button.tintColor = .link
        return button
    }()
    
    init(coordinates: CLLocationCoordinate2D?) {
        self.coordinates = coordinates
        self.isPickable = coordinates == nil
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(doneButtonTapped))
        
        
        map.isUserInteractionEnabled = true
        
        map.addSubview(buttonContainer)
        buttonContainer.addSubview(sendButton)
        
        if isPickable {
            // show send button
            buttonContainer.isHidden = false
            sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
            
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            map.addGestureRecognizer(gesture)
            
        } else {
            // show pin of the location message
            
            buttonContainer.isHidden = true
            guard let mapCoordinates = self.coordinates else {
                return
            }
            
            let pin = MKPointAnnotation()
            pin.coordinate = mapCoordinates
            map.addAnnotation(pin)
        }
        
        view.addSubview(map)
    }
    
    @objc private func doneButtonTapped() {
        print("Done button tapped")
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func sendButtonTapped() {
        print("Send location tapped")
        
        guard let coordinates = coordinates else {
            return
        }
        completion?(coordinates)
        doneButtonTapped()
        print("is pickable \(isPickable)")
    }
    
    @objc private func didTapMap(_ gesture: UITapGestureRecognizer) {
        print("Map tapped")
        
        let locationInView = gesture.location(in: map)
        let mapCoordinates = map.convert(locationInView, toCoordinateFrom: map)
        
        self.coordinates = mapCoordinates
        
        for annotation in map.annotations {
            map.removeAnnotation(annotation)
        }
        
        // drop a pin on the location
        let pin = MKPointAnnotation()
        pin.coordinate = mapCoordinates
        map.addAnnotation(pin)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
        
        let containerSize: CGFloat = 50
        buttonContainer.frame = CGRect(x: map.width*0.8,
                                       y: map.height*0.85,
                                       width: containerSize,
                                       height: containerSize)
        buttonContainer.layer.cornerRadius = containerSize/2
        
        buttonContainer.backgroundColor = .systemBackground
        
        sendButton.frame = CGRect(x: 5,
                                  y: 5,
                                  width: buttonContainer.width-10,
                                  height: buttonContainer.height-10)
    }

}


//part 18?
