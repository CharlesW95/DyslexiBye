//
//  TesseractDimensionsHelper.swift
//  DyslexiBye
//
//  Created by Charles Wong on 11/13/17.
//  Copyright © 2017 Charles Wong. All rights reserved.
//

import Foundation

class TesseractDimensionsHelper {
    
    // Returns a bounding box with unnormalized coordinate
    // values relative to the origin of the uncropped image.
    public static func getFinalBoundingBox(cropRect: CGRect, boundingBox: CGRect) -> CGRect {
        // Unnormalize
        var newX = boundingBox.minX * cropRect.width
        var newY = boundingBox.minY * cropRect.height
        let newWidth = boundingBox.width * cropRect.width
        let newHeight = boundingBox.height * cropRect.height
        
        // Make relative to uncropped image
        newX += cropRect.minX
        newY += cropRect.minY
        
        let finalBoundingBox = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
        return finalBoundingBox
    }
    
    // Returns combined bounding box to project all lines onto the same plane
    public static func getCombinedBoundingBox(cropRect: CGRect, boundingBoxes: [CGRect]) -> CGRect {
        if boundingBoxes.count > 0 { // Valid input
            let firstBox = boundingBoxes[0]
            let origin = CGPoint(x: firstBox.minX * cropRect.width, y: firstBox.minY * cropRect.height)
            var maxWidth: CGFloat = 0
            var totalHeight: CGFloat = 0
            for boundingBox in boundingBoxes {
                let boxWidth = boundingBox.width * cropRect.width
                let boxHeight = boundingBox.height * cropRect.height
                if boxWidth > maxWidth {
                    maxWidth = boxWidth
                }
                totalHeight += boxHeight
            }
            
            return CGRect(x: origin.x, y: origin.y, width: maxWidth, height: totalHeight)
        }
        
        // Default - return empty rect.
        return CGRect(x: 0, y: 0, width: 0, height: 0)
    }
    
    
    
    
}
