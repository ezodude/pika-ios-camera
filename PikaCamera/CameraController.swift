//
//  CameraController.swift
//  PikaCamera
//
//  Created by Ezo Saleh on 06/07/2017.
//  Copyright © 2017 Pika Vision. All rights reserved.
//

import AVFoundation

protocol CameraControllerDelegate : class {
  func cameraController(_ cameraController:CameraController)
  func cameraAccessDenied()
}

class CameraController: NSObject {
  weak var delegate:CameraControllerDelegate?
  var previewLayer:AVCaptureVideoPreviewLayer!
  
  // MARK: Private properties
  fileprivate var session:AVCaptureSession!
  
  // MARK: - Initiliazation
  
  required init(delegate:CameraControllerDelegate) {
    self.delegate = delegate
    super.init()
    initializeSession()
  }
  
  func initializeSession() {
    session = AVCaptureSession()
    session.sessionPreset = AVCaptureSession.Preset.photo
    previewLayer = AVCaptureVideoPreviewLayer(session: self.session) as AVCaptureVideoPreviewLayer
    
    let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    switch authorizationStatus {
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: AVMediaType.video,
                                    completionHandler: { (granted:Bool) -> Void in
                                      if granted {
//                                        self.configureSession()
                                        print("auth granted")
                                      }
                                      else {
                                        self.showAccessDeniedMessage()
                                        print("access denied")
                                      }
      })
    case .authorized:
      print(".authorized")
    case .denied, .restricted:
      print(".denied, .restricted")
    }
  }
}

// MARK: - Private

private extension CameraController {
  func showAccessDeniedMessage() {
    delegate?.cameraAccessDenied()
  }
}
