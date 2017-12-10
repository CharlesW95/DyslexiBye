//
//  ImageCaptureBlock.swift
//  DyslexiBye
//
//  Created by Charles Wong on 11/5/17.
//  Copyright © 2017 Charles Wong. All rights reserved.
//

import UIKit

class ImageCaptureBlock: UIView {
    
    var startingPoint: CGPoint!
    var latestPoint: CGPoint!
    
    init(startingPoint: CGPoint) {
        super.init(frame: CGRect(x: startingPoint.x, y: startingPoint.y, width: 0, height: 0))
        self.startingPoint = startingPoint
        self.latestPoint = startingPoint
        
        configureAppearance()
    }
    
    func configureAppearance() {
        self.layer.borderWidth = 4.0
        self.layer.borderColor = UIColor.yellow.cgColor
        self.backgroundColor = Colors.imageCaptureBackgroundYellow
    }
    
    func updateFrame(newPoint: CGPoint) {
        var topLeft: CGPoint!
        var height: CGFloat!
        var width: CGFloat!
        
        if newPoint.x > 0 {
            width = newPoint.x
            if newPoint.y > 0 { // Bottom
                topLeft = self.startingPoint
                height = newPoint.y
            } else {
                topLeft = CGPoint(x: self.startingPoint.x, y: self.startingPoint.y + newPoint.y)
                height = -newPoint.y
            }
        } else { // ≤ 0
            width = -newPoint.x
            if newPoint.y > 0 {
                topLeft = CGPoint(x: self.startingPoint.x + newPoint.x, y: self.startingPoint.y)
                height = newPoint.y
            } else {
                topLeft = CGPoint(x: self.startingPoint.x + newPoint.x, y: self.startingPoint.y + newPoint.y)
                height = -newPoint.y
            }
        }
        
        self.frame = CGRect(x: topLeft.x, y: topLeft.y, width: width, height: height)
    }
    
    func validAreaCaptured() -> Bool {
        let areaCaptured = self.frame.height * self.frame.width
        return areaCaptured > 10000 // Arbitrary threshold set by trial and error
    }
    
    func returnCenter() -> CGPoint {
        return self.center
    }
    
    func returnFrame() -> CGRect {
        return self.frame
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    

}

