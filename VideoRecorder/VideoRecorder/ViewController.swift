//
//  ViewController.swift
//  VideoRecorder
//
//  Created by Paul Solt on 10/2/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		requestPermissionAndShowCamera()
	}
    
    private func requestPermissionAndShowCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined:
            requestPermission()
        case .restricted:
            fatalError("Video is disabled for parental controls")
        case .denied:
            fatalError("Tell user they need to enable Privacy for Video/Camera/Microphone")
        case .authorized:
            showCamera()
        @unknown default:
            fatalError("A new status was added that we need to handle")
        }
    }
    
    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { (granted) in
            guard granted else {
                fatalError("Tell user they need to enable Privacy for Video/Camera/Microphone")
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.showCamera()
            }
        }
    }
	
	private func showCamera() {
		performSegue(withIdentifier: "ShowCamera", sender: self)
	}
}
