//
//  CameraViewController.swift
//  PikaCamera
//
//  Created by Ezo Saleh on 04/07/2017.
//  Copyright © 2017 Pika Vision. All rights reserved.
//

import UIKit
import QuartzCore

class CameraViewController: UIViewController {
  
  @IBOutlet weak var cameraLabel: UILabel!
  @IBOutlet weak var photoButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    cameraLabel.text = "CAMERA ON"
    photoButton.layer.borderColor = UIColor.yellow.cgColor
  }
  
}
