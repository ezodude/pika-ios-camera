//
//  PhotoCaptureDelegate.swift
//  PikaCamera
//
//  Created by Ezo Saleh on 12/07/2017.
//  Copyright © 2017 Pika Vision. All rights reserved.
//

import AVFoundation
import Photos

class PhotoCaptureProcessor: NSObject {
  private(set) var requestedPhotoSettings: AVCapturePhotoSettings
  
  private let filter: CameraControllerPreviewFilter
  
  private let activeColorSpace: AVCaptureColorSpace
  
  private let willCapturePhotoAnimation: () -> Void
  
  private let livePhotoCaptureHandler: (Bool) -> Void
  
  private let completionHandler: (PhotoCaptureProcessor) -> Void
  
  private var photoData: Data?
  
  private var livePhotoCompanionMovieURL: URL?
  
  init(with requestedPhotoSettings: AVCapturePhotoSettings,
       filter: CameraControllerPreviewFilter,
       activeColorSpace: AVCaptureColorSpace,
       willCapturePhotoAnimation: @escaping () -> Void,
       livePhotoCaptureHandler: @escaping (Bool) -> Void,
       completionHandler: @escaping (PhotoCaptureProcessor) -> Void) {
    self.requestedPhotoSettings = requestedPhotoSettings
    self.filter = filter
    self.activeColorSpace = activeColorSpace
    self.willCapturePhotoAnimation = willCapturePhotoAnimation
    self.livePhotoCaptureHandler = livePhotoCaptureHandler
    self.completionHandler = completionHandler
  }
  
  private func didFinish() {
    if let livePhotoCompanionMoviePath = livePhotoCompanionMovieURL?.path {
      if FileManager.default.fileExists(atPath: livePhotoCompanionMoviePath) {
        do {
          try FileManager.default.removeItem(atPath: livePhotoCompanionMoviePath)
        } catch {
          print("Could not remove file at url: \(livePhotoCompanionMoviePath)")
        }
      }
    }
    
    completionHandler(self)
  }
  
}

extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {
  /*
   This extension includes all the delegate callbacks for AVCapturePhotoCaptureDelegate protocol
   */
  
  func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    if resolvedSettings.livePhotoMovieDimensions.width > 0 && resolvedSettings.livePhotoMovieDimensions.height > 0 {
      livePhotoCaptureHandler(true)
    }
  }
  
  func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    willCapturePhotoAnimation()
  }
  
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
    if error != nil {
      print("Error processing live photo companion movie: \(String(describing: error))")
      return
    }
    livePhotoCompanionMovieURL = outputFileURL
  }
  
  @available(iOS 10.0, *)
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?){
    if let error = error {
      print("Error capturing photo: \(error)")
    } else {
      let original = CIImage(data: AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer)!)
      let filtered = filter == .monochrome ? original?.applyingFilter("CIPhotoEffectNoir", parameters: [:]) : original
      
      // Get a JPEG data representation of the filter output.
      let colorSpaceMap: [AVCaptureColorSpace: CFString] = [
        .sRGB   : CGColorSpace.sRGB,
        .P3_D65 : CGColorSpace.displayP3,
      ]
      let colorSpace = CGColorSpace(name: colorSpaceMap[self.activeColorSpace]!)!
      self.photoData = CIContext().jpegRepresentation(of: filtered!, colorSpace: colorSpace)
    }
  }
  
  @available(iOS 11.0, *)
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    if let error = error {
      print("Error capturing photo: \(error)")
    } else {
      photoData = photo.fileDataRepresentation()
    }
  }
  
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
    if let error = error {
      print("Error capturing photo: \(error)")
      didFinish()
      return
    }
    
    guard let photoData = photoData else {
      print("No photo data resource")
      didFinish()
      return
    }
    
    PHPhotoLibrary.requestAuthorization { [unowned self] status in
      if status == .authorized {
        PHPhotoLibrary.shared().performChanges({ [unowned self] in
          let options = PHAssetResourceCreationOptions()
          let creationRequest = PHAssetCreationRequest.forAsset()
          if #available(iOS 11.0, *) {
            options.uniformTypeIdentifier = self.requestedPhotoSettings.processedFileType.map { $0.rawValue }
          }
          creationRequest.addResource(with: .photo, data: photoData, options: options)
          print("Added photo")
          
          if let livePhotoCompanionMovieURL = self.livePhotoCompanionMovieURL {
            let livePhotoCompanionMovieFileResourceOptions = PHAssetResourceCreationOptions()
            livePhotoCompanionMovieFileResourceOptions.shouldMoveFile = true
            creationRequest.addResource(with: .pairedVideo, fileURL: livePhotoCompanionMovieURL, options: livePhotoCompanionMovieFileResourceOptions)
          }
          
          }, completionHandler: { [unowned self] _, error in
            if let error = error {
              print("Error occurered while saving photo to photo library: \(error)")
            }
            
            self.didFinish()
          }
        )
      } else {
        self.didFinish()
      }
    }
  }
}
