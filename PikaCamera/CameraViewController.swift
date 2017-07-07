//
//  CameraViewController.swift
//  PikaCamera
//
//  Created by Ezo Saleh on 04/07/2017.
//  Copyright © 2017 Pika Vision. All rights reserved.
//

import UIKit
import QuartzCore

class CameraViewController: UIViewController, CameraControllerDelegate {
  var cameraController:CameraController!
  
  @IBOutlet weak var videoPreviewView: UIView!
  @IBOutlet weak var shutterButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    shutterButton.layer.borderColor = UIColor.yellow.cgColor
    
    cameraController = CameraController(delegate: self)
    let previewLayer = cameraController.previewLayer
    previewLayer?.frame = videoPreviewView.bounds
    videoPreviewView.layer.addSublayer(previewLayer!)
  }
  
  // MARK: CameraControllerDelegate funcs
  
  func cameraController(_ cameraController: CameraController) {
  }
  
  func cameraAccessDenied(){
    let alert = UIAlertController(title: "Camera access", message: "Camera access was denied. App is not available.", preferredStyle: UIAlertControllerStyle.alert)
    
    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
    
    self.present(alert, animated: true, completion: nil)
  }
  
}
