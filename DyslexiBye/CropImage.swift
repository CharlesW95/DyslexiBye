//
//  CropImage.swift
//  DyslexiBye
//
//  Created by Charles Wong on 11/5/17.
//  Copyright © 2017 Charles Wong. All rights reserved.
//

import Foundation
extension UIImage {
    // Resizes an input image (self) to a specified size
    func resizeToSize(size: CGSize!) -> UIImage? {
        // Begins an image context with the specified size
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0);
        // Draws the input image (self) in the specified size
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        // Gets an UIImage from the image context
        let result = UIGraphicsGetImageFromCurrentImageContext()
        // Ends the image context
        UIGraphicsEndImageContext();
        // Returns the final image, or NULL on error
        return result;
    }
    
    // Crops an input image (self) to a specified rect
    func crop(rect: CGRect, scaleFactor: CGFloat = 1.0) -> UIImage {
        var newRect = rect
        newRect.origin.x *= scaleFactor
        newRect.origin.y *= scaleFactor
        newRect.size.width *= scaleFactor
        newRect.size.height *= scaleFactor

        let imageRef = self.cgImage!.cropping(to: newRect)
        let image = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
        return image
    }
}
