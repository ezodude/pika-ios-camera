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
  @IBOutlet weak var videoPreviewView: UIView!
  @IBOutlet weak var shutterButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    shutterButton.layer.borderColor = UIColor.yellow.cgColor
  }
  
}
