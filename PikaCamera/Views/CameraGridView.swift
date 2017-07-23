//
//  CameraGridView.swift
//  PikaCamera
//
//  Created by Ezo Saleh on 23/07/2017.
//  Copyright © 2017 Pika Vision. All rights reserved.
//

import UIKit

class CameraGridView: UIView {
  var numberOfColumns:NSInteger = 2
  var numberOfRows:NSInteger = 2
  var lineWidth:CGFloat = 0.5
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.backgroundColor = UIColor.clear
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  // Only override draw() if you perform custom drawing.
  // An empty implementation adversely affects performance during animation.
  override func draw(_ rect: CGRect) {
    let context:CGContext = UIGraphicsGetCurrentContext()!;
    context.setLineWidth(self.lineWidth);
    context.setStrokeColor(UIColor.white.cgColor)
    
    // ---------------------------
    // Drawing column lines
    // ---------------------------
    
    // calculate column width
    let columnWidth:CGFloat = self.frame.size.width / CGFloat(self.numberOfColumns + 1);
    
    for index in 1...self.numberOfColumns {
      let startX:CGFloat = columnWidth * CGFloat(index)
      let startPoint:CGPoint = CGPoint(x:startX, y:0.0)
      let endPoint:CGPoint = CGPoint(x: startX, y:self.frame.size.height)
      
      context.move(to: startPoint)
      context.addLine(to: endPoint)
      context.strokePath()
    }
    
    // ---------------------------
    // Drawing row lines
    // ---------------------------
    
    // calclulate row height
    let rowHeight:CGFloat = self.frame.size.height / CGFloat(self.numberOfRows + 1);
    
    for index in 1...self.numberOfRows {
      let startY:CGFloat = rowHeight * CGFloat(index)
      let startPoint:CGPoint = CGPoint(x:0.0, y:startY)
      let endPoint:CGPoint = CGPoint(x: self.frame.size.width, y:startY)
      
      context.move(to: startPoint)
      context.addLine(to: endPoint)
      context.strokePath()
    }
  }
}
