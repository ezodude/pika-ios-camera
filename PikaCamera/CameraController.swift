//
//  CameraController.swift
//  PikaCamera
//
//  Created by Ezo Saleh on 06/07/2017.
//  Copyright © 2017 Pika Vision. All rights reserved.
//

import AVFoundation

let CameraControllerDidStartSession = "CameraControllerDidStartSession"
let CameraControllerDidStopSession = "CameraControllerDidStopSession"

protocol CameraControllerDelegate : class {
  func cameraController(_ cameraController:CameraController)
  func cameraAccessDenied()
}

class CameraController: NSObject {
  weak var delegate:CameraControllerDelegate?
  var previewLayer:AVCaptureVideoPreviewLayer!
  
  // MARK: Private properties
  fileprivate var sessionQueue:DispatchQueue = DispatchQueue(label: "com.joinpika.camera_session_access_queue", attributes: [])
  
  fileprivate var session:AVCaptureSession!
  fileprivate var currentCameraDevice:AVCaptureDevice?
  fileprivate var backCameraDevice:AVCaptureDevice?
  fileprivate var frontCameraDevice:AVCaptureDevice?
  fileprivate var stillCameraOutput:AVCaptureStillImageOutput!
  
  // MARK: - Initialization
  
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
                                        self.configureSession()
                                        print("auth granted")
                                      }
                                      else {
                                        self.showAccessDeniedMessage()
                                        print("access denied")
                                      }
      })
    case .authorized:
      self.configureSession()
    case .denied, .restricted:
      self.showAccessDeniedMessage()
    }
  }
  
  // MARK: - Camera Control
  
  func startRunning() {
    performConfiguration { () -> Void in
      self.observeValues()
      self.session.startRunning()
      NotificationCenter.default.post(name: Notification.Name(rawValue: CameraControllerDidStartSession), object: self)
    }
  }
  
  func stopRunning() {
    performConfiguration { () -> Void in
      self.unobserveValues()
      self.session.stopRunning()
    }
  }
}

// MARK: - Private

private extension CameraController {
  func performConfiguration(_ block: @escaping (() -> Void)) {
    sessionQueue.async { () -> Void in
      block()
    }
  }
  
  func configureSession() {
    configureDeviceInput()
    configureStillImageCameraOutput()
//    configureFaceDetection()
//
//    if previewType == .manual {
//      configureVideoOutput()
//    }
  }
  
  func configureDeviceInput() {
    performConfiguration { () -> Void in
      
      self.backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
      self.frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
      
      // let's set the back camera as the initial device
      
      self.currentCameraDevice = self.backCameraDevice
      let possibleCameraInput: AnyObject? = try? AVCaptureDeviceInput(device: self.currentCameraDevice!)
      
      if let backCameraInput = possibleCameraInput as? AVCaptureDeviceInput {
        if self.session.canAddInput(backCameraInput) {
          self.session.addInput(backCameraInput)
        }
      }
    }
  }
  
  func configureStillImageCameraOutput() {
    performConfiguration { () -> Void in
      self.stillCameraOutput = AVCaptureStillImageOutput()
      self.stillCameraOutput.outputSettings = [
        AVVideoCodecKey  : AVVideoCodecJPEG,
        AVVideoQualityKey: 0.9
      ]
      
      if self.session.canAddOutput(self.stillCameraOutput) {
        self.session.addOutput(self.stillCameraOutput)
      }
    }
  }
  
  func observeValues() {
  }
  
  func unobserveValues() {
  }
  
  func showAccessDeniedMessage() {
    delegate?.cameraAccessDenied()
  }
}
