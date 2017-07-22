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
  
  @IBOutlet weak var previewContainerView: UIView!
  @IBOutlet weak var videoPreviewView: GLKView!
  @IBOutlet weak var shutterButton: UIButton!
  @IBOutlet weak var colorDetectModeButton: UIButton!
  
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
