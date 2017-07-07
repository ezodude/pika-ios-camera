//
//  CameraController.swift
//  PikaCamera
//
//  Created by Ezo Saleh on 06/07/2017.
//  Copyright © 2017 Pika Vision. All rights reserved.
//

import AVFoundation

class CameraController: NSObject {
  var previewLayer:AVCaptureVideoPreviewLayer!
  
  // MARK: Private properties
  fileprivate var session:AVCaptureSession!
  
  // MARK: - Initiliazation
  
  override init() {
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
//                                        self.showAccessDeniedMessage()
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
