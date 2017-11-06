//
//  FocusAnimationBlock.swift
//  DyslexiBye
//
//  Created by Charles Wong on 10/29/17.
//  Copyright © 2017 Charles Wong. All rights reserved.
//

import UIKit

class FocusAnimationBlock: UIView {
    
    var imageView: UIImageView!
    
    let sideLength: CGFloat = 150.0
    
    init(tapLocation: CGPoint) {
        super.init(frame: CGRect(x: tapLocation.x - sideLength/2, y: tapLocation.y - sideLength/2, width: sideLength, height: sideLength))
        setupImageView()
        rotateImage()
    }
    
    func setupImageView() {
        self.imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.image = UIImage(named: "FocusBlockImage")!
        self.addSubview(self.imageView)
    }
    
    func rotateImage() {
        UIView.animate(withDuration: 1.0, animations: {
            self.imageView.transform = CGAffineTransform(rotationAngle: 180)
        }, completion: { (completed: Bool) -> Void in
            if completed {
                self.rotateImage()
            }
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
