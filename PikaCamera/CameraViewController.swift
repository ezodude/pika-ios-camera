//
//  CameraViewController.swift
//  PikaCamera
//
//  Created by Ezo Saleh on 04/07/2017.
//  Copyright © 2017 Pika Vision. All rights reserved.
//

import UIKit

class CameraViewController: UIViewController {
  
  @IBOutlet weak var cameraLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    cameraLabel.text = "CAMERA ON"
  }
  
}
