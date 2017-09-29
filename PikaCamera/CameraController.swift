//
//  CameraController.swift
//  PikaCamera
//
//  Created by Ezo Saleh on 10/07/2017.
//  Copyright © 2017 Pika Vision. All rights reserved.
//

import AVFoundation
import CoreImage
import UIKit

let CameraControllerDidStartSession = "CameraControllerDidStartSession"
let CameraControllerDidStopSession = "CameraControllerDidStopSession"

enum CameraControllePreviewType {
  case previewLayer
  case manual
}

enum CameraControllerPreviewFilter: String {
  case monochrome
  case none
}

enum DetectedColor {
  case red
  case blue
  case yellow
}

protocol CameraControllerDelegate : class {
  func cameraController(_ cameraController:CameraController)
  func cameraController(_ cameraController:CameraController, didOutputImage: CIImage)
  func cameraAccessDenied()
  func willCapturePhotoAnimation()
  func drawCircle(index: Int, color:UIColor)
}

class CameraController: NSObject {
  weak var delegate:CameraControllerDelegate?
  var previewType:CameraControllePreviewType
  var previewFilter:CameraControllerPreviewFilter
  var previewTiles:[CGRect] = []
  var previewLayer:AVCaptureVideoPreviewLayer!
  var colorDetection:Bool = true
  var detectedColor:DetectedColor = .red
  
  // MARK: Private properties
  fileprivate var sessionQueue:DispatchQueue = DispatchQueue(label: "com.joinpika.camera_session_access_queue", attributes: [])
  
  fileprivate var session:AVCaptureSession!
  fileprivate var ccWrapper:CCWrapper?
  fileprivate var currentCameraDevice:AVCaptureDevice?
  fileprivate var backCameraDevice:AVCaptureDevice?
  fileprivate var frontCameraDevice:AVCaptureDevice?
  fileprivate var photoOutput = AVCapturePhotoOutput()
  fileprivate var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
  fileprivate var videoOutput:AVCaptureVideoDataOutput!
  fileprivate var frameCounter:Int = 0
  fileprivate var ciContext:CIContext?
  fileprivate var glContext:EAGLContext?
  fileprivate let colorSpace = CGColorSpaceCreateDeviceRGB()
  fileprivate let totalRGBBytes = 4
  
  // MARK: - Initialization
  
  required init(previewType: CameraControllePreviewType, previewFilter: CameraControllerPreviewFilter, delegate:CameraControllerDelegate) {
    self.delegate = delegate
    self.previewType = previewType
    self.previewFilter = previewFilter
    
    super.init()
    initializeSession()
    self.ccWrapper = CCWrapper(model: "color_statistic", queue: DispatchQueue(label: "com.joinpika.classify_color", attributes: []))
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
                                      }
                                      else {
                                        self.showAccessDeniedMessage()
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
  
  func changeDetectedColor(_ color:DetectedColor) {
    self.detectedColor = color
  }
  
  // MARK: Capture photo
  
//  func capturePhoto(completionHandler handler: @escaping ((_ image: UIImage, _ metadata:NSDictionary) -> Void)) {
  func capturePhoto() {
    sessionQueue.async { () -> Void in
      
      if let connection = self.photoOutput.connection(with: AVMediaType.video) {
        connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue)!
      }
      
      var photoSettings = AVCapturePhotoSettings()
      
      // Capture HEIF photo when supported, with flash set to auto and high resolution photo enabled.
      if #available(iOS 11.0, *) {
        if  self.photoOutput.availablePhotoCodecTypes.contains(AVVideoCodecType(rawValue: AVVideoCodecType.hevc.rawValue)) {
          photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }
      }
      
      if (self.currentCameraDevice?.isFlashAvailable)! {
        photoSettings.flashMode = .auto
      }
      
      photoSettings.isHighResolutionPhotoEnabled = true
      
      if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
        photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
      }
      
      // Use a separate object for the photo capture delegate to isolate each capture life cycle.
      let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings, filter: self.previewFilter, activeColorSpace: (self.currentCameraDevice?.activeColorSpace)!, willCapturePhotoAnimation: {
        DispatchQueue.main.async { [unowned self] in
          self.delegate?.willCapturePhotoAnimation()
        }
      }, livePhotoCaptureHandler: { capturing  in
        /*
         Because Live Photo captures can overlap, we need to keep track of the
         number of in progress Live Photo captures to ensure that the
         Live Photo label stays visible during these captures.
         */
        print("livePhotoCaptureHandler")
      }, completionHandler: { [unowned self] photoCaptureProcessor in
          // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
          self.sessionQueue.async { [unowned self] in
            self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
          }
        }
      )
      
      /*
       The Photo Output keeps a weak reference to the photo capture delegate so
       we store it in an array to maintain a strong reference to this object
       until the capture is completed.
       */
      self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
      self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
    }
  }
  
}

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
  
  func captureOutput(_ output: AVCaptureOutput,
                     didOutput sampleBuffer: CMSampleBuffer,
                     from connection: AVCaptureConnection){
    
    autoreleasepool{
      let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
      let frame = CIImage(cvPixelBuffer: pixelBuffer!)

      DispatchQueue.main.async { [unowned self] in
        self.delegate?.cameraController(self, didOutputImage: frame)
      }
      
      if self.colorDetection {
        self.frameCounter = (self.frameCounter % self.previewTiles.count) == 0 ? 1 : self.frameCounter + 1;
        let index = self.frameCounter - 1
        let rect = self.previewTiles[index]
        
        let colorAverageFilter = CIFilter(name: "CIAreaMinimum", withInputParameters:[
          kCIInputImageKey: frame,
          kCIInputExtentKey: CIVector(cgRect: rect)
          ])!
        let colorAverage = colorAverageFilter.outputImage!
        let bitmap = calloc(4, MemoryLayout<UInt8>.size)
        
        self.ciContext?.render(colorAverage, toBitmap: bitmap!, rowBytes: self.totalRGBBytes, bounds: colorAverage.extent, format: kCIFormatRGBA8, colorSpace: self.colorSpace)
        
        let bitmapUnsafePointer = bitmap?.assumingMemoryBound(to: UInt8.self)
        let rgba = UnsafeBufferPointer<UInt8>(start: bitmapUnsafePointer, count: self.totalRGBBytes)
        
        let alpha = rgba[3] == 0 ? 1 : CGFloat(rgba[3]) / 255.0
        let red = CGFloat(rgba[0]) / alpha
        let green = CGFloat(rgba[1]) / alpha
        let blue = CGFloat(rgba[2]) / alpha
        let rgb = [NSNumber(value: Int(red)), NSNumber(value: Int(green)), NSNumber(value: Int(blue))]
        
        free(bitmap)
        
        switch self.detectedColor {
        case .red:
          self.ccWrapper?.isRed(rgb, completion: { (detected: Bool) in
            DispatchQueue.main.async { [unowned self] in
              if detected {
//                  print("Red Detected:[\(String(detected))]")
                 self.delegate?.drawCircle(index: index, color: UIColor.red)
              }
            }
          })
        case .blue:
          self.ccWrapper?.isBlue(rgb, completion: { (detected: Bool) in
            DispatchQueue.main.async { [unowned self] in
              if detected {
                //                  print("Red Detected:[\(String(detected))]")
                self.delegate?.drawCircle(index: index, color: UIColor.blue)
              }
            }
          })
        case .yellow:
          self.ccWrapper?.isYellow(rgb, completion: { (detected: Bool) in
            DispatchQueue.main.async { [unowned self] in
              if detected {
                //                  print("Red Detected:[\(String(detected))]")
                self.delegate?.drawCircle(index: index, color: UIColor.yellow)
              }
            }
          })
        }
      }
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
    session.beginConfiguration()
    configureDeviceInput()
    configurePhotoOutput()
    //    configureFaceDetection()
    //
    if previewType == .manual {
      configureVideoOutput()
      generateVideoOutputTiles()
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
      
      if let backCameraInput = possibleCameraInput {
        if self.session.canAddInput(backCameraInput) {
          self.session.addInput(backCameraInput)
        }
      }
    }
  }
  
  func configurePhotoOutput(){
    performConfiguration { () -> Void in
      self.photoOutput = AVCapturePhotoOutput()
      self.photoOutput.isHighResolutionCaptureEnabled = true
      self.photoOutput.isLivePhotoCaptureEnabled = self.photoOutput.isLivePhotoCaptureSupported
      if #available(iOS 11.0, *) {
        self.photoOutput.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliverySupported
      } else {
        // Fallback on earlier versions
      }
      
      if self.session.canAddOutput(self.photoOutput) {
        self.session.addOutput(self.photoOutput)
      }
    }
  }
  
  func configureVideoOutput() {
    performConfiguration { () -> Void in
      self.videoOutput = AVCaptureVideoDataOutput()
      self.videoOutput.videoSettings = nil
      self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.joinpika.video_out_queue", attributes: []))
      self.videoOutput.alwaysDiscardsLateVideoFrames = true
      
      if self.session.canAddOutput(self.videoOutput) {
        self.session.addOutput(self.videoOutput)
      }
      
      if let connection = self.videoOutput.connection(with: AVMediaType.video) {
        if connection.isVideoStabilizationSupported {
          connection.preferredVideoStabilizationMode = .auto
        }
        self.glContext = EAGLContext(api: .openGLES2)
        self.ciContext = CIContext(eaglContext: self.glContext!)
      }else{
        print(">>>>> no connection")
      }
    }
  }
  
  func generateVideoOutputTiles() {
    performConfiguration { () -> Void in
      guard self.videoOutput.connection(with: AVMediaType.video) != nil else {
        return
      }
      let outputWidth = self.videoOutput.videoSettings!["Width"] as! CGFloat
      let outputHeight = self.videoOutput.videoSettings!["Height"] as! CGFloat
      
      let tileWidth:CGFloat = outputWidth / 3.0;
      let tileHeight:CGFloat = outputHeight / 3.0;
      var mirroredTiles:[[CGRect]] = []
      
      for cols in 0...2 {
        var temp:[CGRect] = []
        for rows in 0...2 {
          temp.append(CGRect(x: CGFloat(cols) * tileWidth, y: CGFloat(rows) * tileHeight, width: tileWidth, height: tileHeight))
        }
        mirroredTiles.append(temp.reversed())
      }
      
      self.previewTiles = Array(mirroredTiles.joined())
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

