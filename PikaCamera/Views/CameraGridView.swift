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
  
  var showCircle:Bool = false
  var showCircleRect:CGRect?
  var showCircleColor:UIColor?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.backgroundColor = UIColor.clear
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  func drawCircle(context:CGContext, inRect: CGRect, color:CGColor) {
    context.setLineWidth(2.0)
    context.setFillColor(color)
    
    let x = inRect.origin.x + (inRect.size.width / 2.0)
    let y = inRect.origin.y + (inRect.size.height / 2.0)
    let circle = CGRect(x:x, y:y, width: 30, height: 30)
    context.fillEllipse(in: circle)
  }
  
  // Only override draw() if you perform custom drawing.
  // An empty implementation adversely affects performance during animation.
  override func draw(_ rect: CGRect) {
    let context:CGContext = UIGraphicsGetCurrentContext()!;
    context.clear(rect)
    
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
    
    if showCircle {
      drawCircle(context: context, inRect: showCircleRect!, color: (showCircleColor?.cgColor)!)
    }
  }
}
