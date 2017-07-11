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
  
  @IBOutlet weak var videoPreviewView: GLKView!
  
  fileprivate var glContext:EAGLContext?
  fileprivate var ciContext:CIContext?
  fileprivate var glView:GLKView {
    get {
      return videoPreviewView
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
//    shutterButton.layer.borderColor = UIColor.yellow.cgColor
    
    glContext = EAGLContext(api: .openGLES2)
    glView.context = glContext!
    glView.drawableDepthFormat = .format24
    glView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
    
    if let window = view.window {
      glView.frame = window.bounds
    }
    
    ciContext = CIContext(eaglContext: glContext!)
    cameraController = CameraController(previewType: .manual, delegate: self)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    cameraController.startRunning()
  }
  
  func cameraController(_ cameraController: CameraController) {
    
  }
  
  func cameraController(_ cameraController: CameraController, didOutputImage image: CIImage) {
    if glContext != EAGLContext.current() {
      EAGLContext.setCurrent(glContext)
    }
    
    glView.bindDrawable()
    ciContext?.draw(image, in: image.extent, from: image.extent)
    glView.display()
  }
  
  func cameraAccessDenied() {
    
  }
  
}
