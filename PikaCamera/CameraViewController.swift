//
//  CameraViewController.swift
//  PikaCamera
//
//  Created by Ezo Saleh on 10/07/2017.
//  Copyright © 2017 Pika Vision. All rights reserved.
//

import UIKit
import GLKit
import OpenGLES

class CameraViewController: UIViewController, CameraControllerDelegate {
  var cameraController:CameraController!
  var colorDetectionActive:Bool = false
  
  @IBOutlet weak var previewContainerView: UIView!
  @IBOutlet weak var videoPreviewView: GLKView!
  @IBOutlet weak var shutterButton: UIButton!
  @IBOutlet weak var colorDetectModeButton: UIButton!
  @IBOutlet weak var redDetectorButton: UIButton!
  @IBOutlet weak var blueDetectorButton: UIButton!
  @IBOutlet weak var yellowDetectorButton: UIButton!
  
  fileprivate var glContext:EAGLContext?
  fileprivate var ciContext:CIContext?
  fileprivate var glView:GLKView {
    get {
      return videoPreviewView
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    shutterButton.layer.borderColor = UIColor.yellow.cgColor
    colorDetectModeButton.layer.borderColor = UIColor.black.cgColor
    
    glContext = EAGLContext(api: .openGLES2)
    glView.context = glContext!
    glView.drawableDepthFormat = .format24
    glView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
    glView.frame = videoPreviewView.bounds
    
    ciContext = CIContext(eaglContext: glContext!)
    cameraController = CameraController(previewType: .manual, previewFilter: .monochrome, previewBounds: videoPreviewView.bounds, delegate: self)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    cameraController.startRunning()
  }
  
  // Mark: Actions
  
  @IBAction func handleShutterButton(_ sender: UIButton) {
      cameraController.capturePhoto()
  }
  
  @IBAction func toggleColorDetection(_ sender: UIButton) {
    colorDetectionActive = !colorDetectionActive
    
    redDetectorButton.layer.backgroundColor = colorDetectionActive ? UIColor.red.cgColor : UIColor.lightGray.cgColor
    redDetectorButton.isEnabled = colorDetectionActive
    redDetectorButton.layer.borderColor = UIColor.clear.cgColor
    
    blueDetectorButton.layer.backgroundColor = colorDetectionActive ? UIColor.blue.cgColor : UIColor.lightGray.cgColor
    blueDetectorButton.isEnabled = colorDetectionActive
    blueDetectorButton.layer.borderColor = UIColor.clear.cgColor
    
    yellowDetectorButton.layer.backgroundColor = colorDetectionActive ? UIColor.yellow.cgColor : UIColor.lightGray.cgColor
    yellowDetectorButton.isEnabled = colorDetectionActive
    yellowDetectorButton.layer.borderColor = UIColor.clear.cgColor
    
    if colorDetectionActive {
      detectRed(redDetectorButton)
    }
    cameraController.toggleColorDetection()
  }
  
  @IBAction func detectRed(_ sender: UIButton) {
    redDetectorButton.layer.borderColor = UIColor.white.cgColor
    blueDetectorButton.layer.borderColor = UIColor.clear.cgColor
    yellowDetectorButton.layer.borderColor = UIColor.clear.cgColor
  }
  
  @IBAction func detectBlue(_ sender: UIButton) {
    redDetectorButton.layer.borderColor = UIColor.clear.cgColor
    blueDetectorButton.layer.borderColor = UIColor.white.cgColor
    yellowDetectorButton.layer.borderColor = UIColor.clear.cgColor
  }
  
  @IBAction func detectYellow(_ sender: UIButton) {
    redDetectorButton.layer.borderColor = UIColor.clear.cgColor
    blueDetectorButton.layer.borderColor = UIColor.clear.cgColor
    yellowDetectorButton.layer.borderColor = UIColor.white.cgColor
  }
  // Mark: Delegates
  
  func cameraController(_ cameraController: CameraController, didOutputImage image: CIImage) {
    if glContext != EAGLContext.current() {
      EAGLContext.setCurrent(glContext)
    }
    
    glView.bindDrawable()
    ciContext?.draw(image, in: image.extent, from: image.extent)
    glView.display()
  }
  
  func cameraController(_ cameraController: CameraController) {
  }
  
  func cameraAccessDenied() {
  }
  
  func willCapturePhotoAnimation() {
    print("willCapturePhotoAnimation animate view for photo capture > glView opacity 0")
    self.glView.layer.opacity = 0
    UIView.animate(withDuration: 0.25) { [unowned self] in
      self.glView.layer.opacity = 1
    }
  }
}
