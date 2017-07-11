//
//  CameraController.swift
//  PikaCamera
//
//  Created by Ezo Saleh on 10/07/2017.
//  Copyright © 2017 Pika Vision. All rights reserved.
//

import AVFoundation
import CoreImage

let CameraControllerDidStartSession = "CameraControllerDidStartSession"
let CameraControllerDidStopSession = "CameraControllerDidStopSession"

enum CameraControllePreviewType {
  case previewLayer
  case manual
}

protocol CameraControllerDelegate : class {
  func cameraController(_ cameraController:CameraController)
  func cameraController(_ cameraController:CameraController, didOutputImage: CIImage)
  func cameraAccessDenied()
}

class CameraController: NSObject {
  weak var delegate:CameraControllerDelegate?
  var previewType:CameraControllePreviewType
  var previewLayer:AVCaptureVideoPreviewLayer!
  
  // MARK: Private properties
  fileprivate var sessionQueue:DispatchQueue = DispatchQueue(label: "com.joinpika.camera_session_access_queue", attributes: [])
  
  fileprivate var session:AVCaptureSession!
  fileprivate var currentCameraDevice:AVCaptureDevice?
  fileprivate var backCameraDevice:AVCaptureDevice?
  fileprivate var frontCameraDevice:AVCaptureDevice?
  fileprivate var stillCameraOutput:AVCaptureStillImageOutput!
  fileprivate var videoOutput:AVCaptureVideoDataOutput!
  fileprivate var filter: CIFilter!
  
  // MARK: - Initialization
  
  required init(previewType:CameraControllePreviewType, delegate:CameraControllerDelegate) {
    self.delegate = delegate
    self.previewType = previewType
    
    super.init()
    initializeSession()
    configureFilter()
  }
  
  
  convenience init(delegate:CameraControllerDelegate) {
    self.init(previewType: .previewLayer, delegate: delegate)
  }
  
  func initializeSession() {
    session = AVCaptureSession()
    session.sessionPreset = AVCaptureSession.Preset.photo
    
    if previewType == .previewLayer {
      previewLayer = AVCaptureVideoPreviewLayer(session: self.session) as AVCaptureVideoPreviewLayer
    }
    
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

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
  
  func captureOutput(_ output: AVCaptureOutput,
                     didOutput sampleBuffer: CMSampleBuffer,
                     from connection: AVCaptureConnection){
    
    let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    let frame = CIImage(cvPixelBuffer: pixelBuffer!)
    print(">>>>> captured Output \(frame)")
    
    self.filter.setValue(frame, forKey: kCIInputImageKey)
    guard let filteredFrame = filter.outputImage else {
      return
    }
    self.delegate?.cameraController(self, didOutputImage: filteredFrame)
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
    session.beginConfiguration()
    configureDeviceInput()
    configureStillImageCameraOutput()
    //    configureFaceDetection()
    //
    if previewType == .manual {
      configureVideoOutput()
    }
    self.session.commitConfiguration()
  }
  
  func configureDeviceInput() {
    performConfiguration { () -> Void in
      
      self.backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
      self.frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
      
      // let's set the back camera as the initial device
      
      self.currentCameraDevice = self.backCameraDevice
      let possibleCameraInput = try? AVCaptureDeviceInput(device: self.currentCameraDevice!)
      print(">>>>> possibleCameraInput: \(String(describing: possibleCameraInput))")
      
      if let backCameraInput = possibleCameraInput as? AVCaptureDeviceInput {
        if self.session.canAddInput(backCameraInput) {
          self.session.addInput(backCameraInput)
          print(">>>>> session added input from back camera")
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
  
  func configureVideoOutput() {
    performConfiguration { () -> Void in
      self.videoOutput = AVCaptureVideoDataOutput()
      self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.joinpika.video_out_queue", attributes: []))
      self.videoOutput.alwaysDiscardsLateVideoFrames = true
      
      if self.session.canAddOutput(self.videoOutput) {
        self.session.addOutput(self.videoOutput)
        print(">>>>> added video output to session")
      }
      
      if let connection = self.videoOutput.connection(with: AVMediaType.video) {
        print(">>>>> connection \(connection)")
        if connection.isVideoStabilizationSupported {
          connection.preferredVideoStabilizationMode = .auto
        }
      }else{
        print(">>>>> no connection")
      }
    }
  }
  
  func configureFilter(){
    performConfiguration { () -> Void in
      self.filter = CIFilter(
        name: "CIColorMonochrome",
        withInputParameters: [
          "inputColor" : CIColor(red: 1.0, green: 1.0, blue: 1.0),
          "inputIntensity" : 1.0
        ]
      )
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

