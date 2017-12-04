//
//  ARKitHelper.swift
//  DyslexiBye
//
//  Created by Charles Wong on 11/13/17.
//  Copyright © 2017 Charles Wong. All rights reserved.
//

import Foundation
import ARKit
import SceneKit


// Contains all methods related to ARKit
class ARKitHelper: NSObject {
    
    var sceneView: ARSCNView
    var latestCornerFeaturePoints: [ARHitTestResult]
    
    
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
        self.latestCornerFeaturePoints = [ARHitTestResult]()
    }
    
    func hitTest(testPoint: CGPoint) -> (Bool, ARHitTestResult?) {
        let hitTestResults = self.sceneView.hitTest(testPoint, types: .featurePoint)
        
        if let hitResult = hitTestResults.first {
            return (true, hitResult)
        }
        return (false, nil)
    }
    
    func gte(one: CGFloat, two: CGFloat) -> Bool {
        return one >= two
    }
    
    func lte(one: CGFloat, two: CGFloat) -> Bool {
        return one <= two
    }
    
    func conductHitTest(origin: CGPoint, increment: CGFloat, limit: CGFloat, comparator: (CGFloat, CGFloat) -> Bool) -> (ARHitTestResult?, CGFloat) {
        var currentX = origin.x
        while(comparator(currentX, limit)) {
            let testPoint = CGPoint(x: currentX, y: origin.y)
            let results = self.sceneView.hitTest(testPoint, types: .featurePoint)
            if let hitResult = results.first {
                return (hitResult, currentX)
            } else {
                currentX += increment
            }
        }
        return (nil, currentX)
    }
    
    func fourCornerHitTest(startingPoint: CGPoint, width: CGFloat, height: CGFloat) -> [ARHitTestResult] {
        
        let endX = startingPoint.x + width
        let endY = startingPoint.y + height
        
        let topLeft = startingPoint
        let topRight = CGPoint(x: endX, y: startingPoint.y)
        let bottomLeft = CGPoint(x: startingPoint.x, y: endY)
        let bottomRight = CGPoint(x: endX, y: endY)
        
        let increment: CGFloat = 1.0
        
        var hitTestResults = [ARHitTestResult]()
        
        let tlResults = conductHitTest(origin: topLeft, increment: increment, limit: endX, comparator: lte)
        if let tlHit = tlResults.0 {
            hitTestResults.append(tlHit)
            let trResults = conductHitTest(origin: topRight, increment: -increment, limit: tlResults.1, comparator: gte)
            if let trHit = trResults.0 {
                hitTestResults.append(trHit)
                let blResults = conductHitTest(origin: bottomLeft, increment: increment, limit: endX, comparator: lte)
                if let blHit = blResults.0 {
                    hitTestResults.append(blHit)
                    let brResults = conductHitTest(origin: bottomRight, increment: -increment, limit: blResults.1, comparator: gte)
                    if let brHit = brResults.0 {
                        hitTestResults.append(brHit)
                        return hitTestResults // Success (4 corners identified)
                    }
                }
            }
        }
        
        // Failed, return empty list
        return [ARHitTestResult]()
    }
    
    func euclideanDistanceHitTestResult(first: SCNVector3, second: SCNVector3) -> CGFloat {
        var sum: CGFloat = 0
        sum += CGFloat(pow(first.x - second.x, 2))
        sum += CGFloat(pow(first.y - second.y, 2))
        sum += CGFloat(pow(first.z - second.z, 2))
        return CGFloat(pow(sum, 0.5))
    }
    
    func createPlane(vectors: [SCNVector3]) -> SCNPlane {
        let width = euclideanDistanceHitTestResult(first: vectors[0], second: vectors[1])
        let height = euclideanDistanceHitTestResult(first: vectors[0], second: vectors[2])
        let widthScaleFactor: CGFloat = 1.5, heightScaleFactor: CGFloat = 1.8
        return SCNPlane(width: width * widthScaleFactor, height: height * heightScaleFactor)
    }
    
    // Returns AB
    func calculateDirectionalVectorAB(a: SCNVector3, b: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            b.x - a.x,
            b.y - a.y,
            b.z - a.z
        )
    }
    
    func hitTestResultsToSCNVector3(results: [ARHitTestResult]) -> [SCNVector3] {
        return results.map { hitTestResultToSCNVector3(hitTestResult: $0) }
    }
    
    func hitTestResultToSCNVector3(hitTestResult: ARHitTestResult) -> SCNVector3 {
        return SCNVector3(
            hitTestResult.worldTransform.columns.3.x,
            hitTestResult.worldTransform.columns.3.y,
            hitTestResult.worldTransform.columns.3.z
        )
    }
    
    func calculateNormalVector(vectors: [SCNVector3]) -> SCNVector3 {
        let a = vectors[0]
        let b = vectors[1]
        let c = vectors[2]
        
        let ab = calculateDirectionalVectorAB(a: a, b: b)
        let bc = calculateDirectionalVectorAB(a: b, b: c)
        
        let normalVec = crossProduct(a: ab, b: bc)
        
        return normalize(vec: normalVec)
    }
    
    func negateVector(vec: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            -vec.x,
            -vec.y,
            -vec.z
        )
    }
    
    func calculateMagnitude(vec: SCNVector3) -> Float {
        var sum: Float = 0
        sum += pow(vec.x, 2)
        sum += pow(vec.y, 2)
        sum += pow(vec.z, 2)
        return pow(sum, 0.5)
    }
    
    func normalize(vec: SCNVector3) -> SCNVector3 {
        let mag = calculateMagnitude(vec: vec)
        return SCNVector3(
            vec.x / mag,
            vec.y / mag,
            vec.z / mag
        )
    }
    
    func crossProduct(a: SCNVector3, b: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            a.y * b.z - a.z * b.y,
            a.z * b.x - a.x * b.z,
            a.x * b.y - a.y * b.x
        )
    }
    
    func dotProd(a: SCNVector3, b: SCNVector3) -> Float {
        return a.x * b.x + a.y * b.y + a.z * b.z
    }
    
    func scaleVector(vector: SCNVector3, scale: Float) -> SCNVector3 {
        return SCNVector3(
            vector.x * scale,
            vector.y * scale,
            vector.z * scale
        )
    }
 
    // Returns rotation angle in radians
    func calculatePlaneRotationAngle(normal: SCNVector3, original: SCNVector3) -> Float {
        let normalizedNormal = self.normalize(vec: normal)
        let normalizedOriginal = self.normalize(vec: original)
        let cosineAngle = dotProd(a: normalizedNormal, b: normalizedOriginal)
        return acos(cosineAngle)
    }
    
    // Returns rotation axis for plane rotation
    func calculateRotationAxis(normal: SCNVector3, original: SCNVector3) -> SCNVector3 {
        let crossed = self.crossProduct(a: normal, b: original)
        return self.normalize(vec: crossed)
    }

    func populateFeaturePoints(rect: CGRect) {
        self.latestCornerFeaturePoints = self.featurePointsForThreeCorners(box: rect)
    }
    
    func featurePointsForThreeCorners(box: CGRect) -> [ARHitTestResult] {
        let topLeft = box.origin
        let topRight = CGPoint(x: box.origin.x + box.width, y: box.origin.y)
        let bottomLeft = CGPoint(x: box.origin.x, y: box.origin.y + box.height)
        
        let points = [topLeft, topRight, bottomLeft]
        var featurePoints = [ARHitTestResult]()
        
        for point in points {
            if let fp = nearestFeaturePoint(starting: point, exceptions: featurePoints) {
                featurePoints.append(fp)
            }
        }
        
        return featurePoints
    }
    
    
    // Searches for the nearest feature point in a counter-clockwise spiral.
    func nearestFeaturePoint(starting: CGPoint, exceptions: [ARHitTestResult]) -> ARHitTestResult? {
        var spiralWidth = 2 // Starts at 2
        var iterations = 500 // Maximum number of steps
        
        // Start from bottom right
        var currentPosition = shiftPoint(initial: starting, incrementX: 1, incrementY: 1)
        
        while iterations > 0 {
            // Up, Left, Down, Right
            let xyIncrements: [(CGFloat, CGFloat)] = [(0, -1), (-1 , 0), (0, 1), (1, 0)]
            
            for increments in xyIncrements {
                let results = shiftAndTest(initial: currentPosition, incrementX: increments.0, incrementY: increments.1, iterations: spiralWidth)
                iterations -= spiralWidth
                
                if results.0 {
                    let hitResult = results.1!
                    var validPointFound = true
                    for point in exceptions {
                        if hitResult.localTransform == point.localTransform {
                            validPointFound = false // Keep looking
                            break
                        }
                    }
                    
                    if validPointFound {
                        return hitResult
                    }
                }
                
                currentPosition = results.2
            }
            
            // Shift to new bottom right
            currentPosition = shiftPoint(initial: currentPosition, incrementX: 1, incrementY: 1)
            spiralWidth += 2 // New Spiral
        }
        
        // Unable to find nearest point
        return nil
    }
    
    // Move along one side of the spiral, performing hit tests.
    func shiftAndTest(initial: CGPoint, incrementX: CGFloat, incrementY: CGFloat, iterations: Int) -> (Bool, ARHitTestResult?, CGPoint) {
        var testPoint = initial
        for _ in 0..<iterations {
            // Shift to new point
            testPoint = shiftPoint(initial: initial, incrementX: incrementX, incrementY: incrementY)
            // Perform hitTest
            let hitTestResult = hitTest(testPoint: testPoint)
            if hitTestResult.0 { // Feature Point found
                return (hitTestResult.0, hitTestResult.1, testPoint)
            }
        }
        return (false, nil, testPoint)
    }
    
    func shiftPoint(initial: CGPoint, incrementX: CGFloat, incrementY: CGFloat) -> CGPoint {
        return CGPoint(x: initial.x + incrementX, y: initial.y + incrementY)
    }
    
    // Use position offset instead of pivot translation to place plane to preserve
    // rotation point.
    func offsetPlanePosition(pos: SCNVector3, planeGeometry: SCNPlane, vectors: [SCNVector3]) -> SCNVector3 {
        // Move in the positive x direction and negative y direction.
        let positiveXDirection = self.normalize(vec: self.calculateDirectionalVectorAB(a: vectors[0], b: vectors[1]))
        let negativeYDirection = self.normalize(vec: self.calculateDirectionalVectorAB(a: vectors[0], b: vectors[2]))
        
        let xOffset = self.scaleVector(vector: positiveXDirection, scale: Float(planeGeometry.width/2))
        let yOffset = self.scaleVector(vector: negativeYDirection, scale: Float(planeGeometry.height/2))
        
        return SCNVector3(
            pos.x + xOffset.x + yOffset.x,
            pos.y + xOffset.y + yOffset.y,
            pos.z + xOffset.z + yOffset.z
        )
    }
    
    func insertPlaneIntoScene(finalBox: CGRect, lines: [String]) -> Bool {
        let corners = self.latestCornerFeaturePoints
        let cornerVectors = self.hitTestResultsToSCNVector3(results: corners)
        if cornerVectors.count == 3 {
            let plane = createPlane(vectors: cornerVectors)
            var normalVec = calculateNormalVector(vectors: cornerVectors)
            normalVec = negateVector(vec: normalVec)
            
            // Calculate rotation
            let originalNormal = SCNVector3(0, 0, 1)
            let rotationAxis = calculateRotationAxis(normal: normalVec, original: originalNormal)
            let rotationAngle = calculatePlaneRotationAngle(normal: normalVec, original: originalNormal)
            
            // Create position vector
            let position = cornerVectors[0]
            let finalPos = offsetPlanePosition(pos: position, planeGeometry: plane, vectors: cornerVectors)
            let planeNode = createPlaneNode(position: finalPos, rotationAxis: rotationAxis, rotationAngle: rotationAngle)
            
            let gridMaterial = SCNMaterial()
            gridMaterial.isDoubleSided = true
            gridMaterial.diffuse.contents = UIColor.yellow
            plane.materials = [gridMaterial]
            planeNode.geometry = plane
            
            sceneView.scene.rootNode.addChildNode(planeNode)
            
            // Insert text onto plane
            insertTextOntoPlane(planeNode: planeNode, lines: lines)
            
            print("Plane was inserted")
            
            // MARK FEATURES
            markFeaturePoints(hitResults: corners, normal: normalVec, original: originalNormal)
            return true
        } else {
            return false
        }
    }
    
    func createPlaneNode(position: SCNVector3, rotationAxis: SCNVector3, rotationAngle: Float) -> SCNNode {
        let planeNode = SCNNode()
        planeNode.position = position
        planeNode.rotation = SCNVector4(rotationAxis.x, rotationAxis.y, rotationAxis.z, -rotationAngle)
        return planeNode
    }
    
    func cleanStrings(lines: [String]) -> [String] {
        return lines.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .filter {
            return $0.count > 0
        }
    }
    
    func constructStringFromLines(lines: [String]) -> String {
        return lines.joined(separator: "\r")
    }
    
    // Computes how much the text has to be scaled.
    func getTextScale(planeNode: SCNNode, textNode: SCNNode) -> Float {
        let planeCoordinates = boundingBoxToDimensions(boundingBox: planeNode.boundingBox)
        let textCoordinates = boundingBoxToDimensions(boundingBox: textNode.boundingBox)
        
        let widthScale = planeCoordinates.0 / textCoordinates.0
        let heightScale = planeCoordinates.1 / textCoordinates.1
        
        // Return the more extreme scale factor
        let margin: Float = 0.9 // Leaves margins on the sides
        return min(widthScale, heightScale) * margin
    }
    
    // Returns Width, Height, Depth
    func boundingBoxToDimensions(boundingBox: (min: SCNVector3, max: SCNVector3)) -> (Float, Float, Float) {
        let width = abs(boundingBox.max.x - boundingBox.min.x)
        let height = abs(boundingBox.max.y - boundingBox.min.y)
        let depth = abs(boundingBox.max.z - boundingBox.min.z)
        
        return (width, height, depth)
    }
    
    func insertTextOntoPlane(planeNode: SCNNode, lines: [String]) {
        let cleanedStrings = cleanStrings(lines: lines)
        
        let finalText = constructStringFromLines(lines: cleanedStrings)
        let textGeom = SCNText(string: finalText, extrusionDepth: 1.0)
        textGeom.font = UIFont(name: "Dyslexie-Regular", size: 12.0)
        textGeom.firstMaterial?.diffuse.contents = UIColor(red: 4/255, green: 111/255, blue: 191/255, alpha: 1)
        
        let textNode = SCNNode(geometry: textGeom)
        let textScale = getTextScale(planeNode: planeNode, textNode: textNode)
        textNode.scale = SCNVector3(textScale, textScale, textScale)

        let textHeight = textGeom.boundingBox.max.y - textGeom.boundingBox.min.y
        let textWidth = textGeom.boundingBox.max.x - textGeom.boundingBox.min.x
        textNode.pivot = SCNMatrix4MakeTranslation(textWidth/2, textHeight/2, 0)
        planeNode.addChildNode(textNode)
    }
    
    // Dev Feature to mark actual spots
    func markFeaturePoints(hitResults: [ARHitTestResult], normal: SCNVector3, original: SCNVector3) {
        for (i, res) in hitResults.enumerated() {
            let fp = SCNSphere(radius: 0.5)
            fp.firstMaterial?.diffuse.contents = UIColor.red
            let node = SCNNode(geometry: fp)
            node.position = SCNVector3(
                res.worldTransform.columns.3.x,
                res.worldTransform.columns.3.y,
                res.worldTransform.columns.3.z
            );
            
            if i == 0 {
                node.scale = SCNVector3(0.005, 0.005, 0.005)
            } else {
                node.scale = SCNVector3(0.002, 0.002, 0.002)
            }
            sceneView.scene.rootNode.addChildNode(node)
            
//            for i in 1...5 {
//                let endVecSphere = SCNSphere(radius: 0.5)
//                endVecSphere.firstMaterial?.diffuse.contents = UIColor.blue
//                let node = SCNNode(geometry: endVecSphere)
//                let distMultiplier: Float = 0.01 * Float(i)
//                node.position = SCNVector3(
//                    res.worldTransform.columns.3.x + normal.x * distMultiplier,
//                    res.worldTransform.columns.3.y + normal.y * distMultiplier,
//                    res.worldTransform.columns.3.z + normal.z * distMultiplier
//                )
//                node.scale = SCNVector3(0.003, 0.003, 0.003)
//                sceneView.scene.rootNode.addChildNode(node)
//            }
//
//            for i in 1...10 {
//                let endVecSphere = SCNSphere(radius: 0.5)
//                endVecSphere.firstMaterial?.diffuse.contents = UIColor.green
//                let node = SCNNode(geometry: endVecSphere)
//                let distMultiplier: Float = 0.005 * Float(i)
//                node.position = SCNVector3(
//                    res.worldTransform.columns.3.x + original.x * distMultiplier,
//                    res.worldTransform.columns.3.y + original.y * distMultiplier,
//                    res.worldTransform.columns.3.z + original.z * distMultiplier
//                )
//                node.scale = SCNVector3(0.003, 0.003, 0.003)
//                sceneView.scene.rootNode.addChildNode(node)
//            }
            
            
        }
    }
}
