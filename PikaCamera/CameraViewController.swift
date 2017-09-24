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
  
//  @IBOutlet weak var shutterButton: UIButton!
  @IBOutlet weak var colorDetectModeButton: UIButton!
  @IBOutlet weak var redDetectorButton: UIButton!
  @IBOutlet weak var blueDetectorButton: UIButton!
  @IBOutlet weak var yellowDetectorButton: UIButton!
  
  fileprivate var glContext:EAGLContext?
  fileprivate var ciContext:CIContext?
  fileprivate var gridView: CameraGridView!
  fileprivate var gridViewColorDots: [UIView] = []
  
  fileprivate var glView:GLKView {
    get {
      return videoPreviewView
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
//    shutterButton.layer.borderColor = UIColor.yellow.cgColor
    colorDetectModeButton.layer.borderColor = UIColor.black.cgColor
    
    glContext = EAGLContext(api: .openGLES2)
    glView.context = glContext!
    glView.drawableDepthFormat = .format24
    glView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
    glView.frame = videoPreviewView.bounds
    gridView = CameraGridView.init(frame: videoPreviewView.bounds)
    buildGridColorDotViews(for: gridView.tiles)
    glView.insertSubview(gridView, at: 1)
    
    ciContext = CIContext(eaglContext: glContext!)
    cameraController = CameraController(previewType: .manual, previewFilter: .monochrome, delegate: self)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    cameraController.startRunning()
  }
  
  // Mark: Actions
  
//  @IBAction func handleShutterButton(_ sender: UIButton) {
//      cameraController.capturePhoto()
//  }
  
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
    cameraController.changeDetectedColor(.red)
  }
  
  @IBAction func detectBlue(_ sender: UIButton) {
    redDetectorButton.layer.borderColor = UIColor.clear.cgColor
    blueDetectorButton.layer.borderColor = UIColor.white.cgColor
    yellowDetectorButton.layer.borderColor = UIColor.clear.cgColor
    cameraController.changeDetectedColor(.blue)
  }
  
  @IBAction func detectYellow(_ sender: UIButton) {
    redDetectorButton.layer.borderColor = UIColor.clear.cgColor
    blueDetectorButton.layer.borderColor = UIColor.clear.cgColor
    yellowDetectorButton.layer.borderColor = UIColor.white.cgColor
    cameraController.changeDetectedColor(.yellow)
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
    self.glView.layer.opacity = 0
    UIView.animate(withDuration: 0.25) { [unowned self] in
      self.glView.layer.opacity = 1
    }
  }
  
  func drawCircle(index: Int, color: UIColor) {
    let dot = gridViewColorDots[index]
    dot.layer.backgroundColor = color.cgColor
    dot.layer.opacity = 1
    
    UIView.animate(withDuration: 0.3) {
      dot.layer.opacity = 0
      dot.layer.backgroundColor = UIColor.clear.cgColor
    }
  }
  
  func buildGridColorDotViews(for tiles:[CGRect]) {
    let size:CGFloat = 30.0
    
    for tile in tiles {
      let x = tile.origin.x + (tile.size.width / 2.0)
      let y = tile.origin.y + (tile.size.height / 2.0) - (size / 2.0)
      
      let dotView = UIView(frame: CGRect(x: x, y: y, width: size, height: size))
      let saveCenter:CGPoint = dotView.center;
      
      dotView.layer.cornerRadius = size / 2.0;
      dotView.clipsToBounds = true
      dotView.center = saveCenter
      dotView.layer.opacity = 0.0
//      let key = getKey(tile)
//      gridViewColorDots[i + 1] = dotView
      gridViewColorDots.append(dotView)
      gridView.insertSubview(dotView, at:1)
    }
  }
}
