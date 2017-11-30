//
//  ViewController.swift
//  DyslexiBye
//
//  Created by Charles Wong on 10/3/17.
//  Copyright © 2017 Charles Wong. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation
import TesseractOCR
import GPUImage

class ViewController: UIViewController, ARSCNViewDelegate, G8TesseractDelegate, AVCapturePhotoCaptureDelegate {
    
    // App State
    var firing = false
    var focusCounter = 0
    
    // AVCaptureSession Variables
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var stillImageOutput: AVCapturePhotoOutput!
    var cropRectangle: CGRect!
    
    // Custom Visual Elements
    var focusAnimationBlock: FocusAnimationBlock?
    var imageCaptureBlock: ImageCaptureBlock?
    
    var tesseractTextView: UITextView?
    var originalImageView: UIImageView?
    var processedImageView: UIImageView?
    
    // Tesseract Variables
    var tesseract: G8Tesseract!
    
    // ARKit Variables
    var configuration: ARWorldTrackingConfiguration!
    var arHelper: ARKitHelper!
    
    var latestPlaneCorners = [ARHitTestResult]()
    
    @IBOutlet weak var displayImageView: UIImageView!
    
    @IBAction func panGestureRecognized(_ sender: Any) {
        let sender = sender as! UIPanGestureRecognizer
        switch (sender.state) {
            case .began:
                print("This is the starting location")
                print(sender.location(in: self.view))
                // Initialize the ImageCaptureBlock
                self.imageCaptureBlock = ImageCaptureBlock(startingPoint: sender.location(in: self.view))
                self.view.addSubview(self.imageCaptureBlock!)
            case .changed:
                // Change the size of the box
                let newPoint = sender.translation(in: self.view)
                self.imageCaptureBlock?.updateFrame(newPoint: newPoint)
            case .ended:
                // Check to see if there is a proper area
                if let captureBlock = self.imageCaptureBlock {
                    removeImageCaptureBlock()
                    if captureBlock.validAreaCaptured() {
                        // Start image capture
                        self.cropRectangle = captureBlock.returnFrame()
                        arHelper.populateFeaturePoints(rect: self.cropRectangle)
                        startImageFocus(center: captureBlock.returnCenter())
                    } else {
                        print("Area was invalid for photo capture.")
                    }
                }
            default:
                print("Unexpected case found.")
        }
    }
    
    func startImageFocus(center: CGPoint) {
        // Hide the sceneView temporarily
        sceneView.session.pause() // Pause the ARSession
        // Set up ARCaptureSession
        let captureDevice = AVCaptureDevice.default(for: .video)
        
        do {
            // Input setup
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession = AVCaptureSession()
            captureSession.addInput(input)
            
            // Output setup
            self.stillImageOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(stillImageOutput) {
                captureSession.addOutput(stillImageOutput)
            }
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
            videoPreviewLayer?.frame = self.view.layer.bounds
            print("Starting process...")
            captureSession.startRunning()
            
            // Show the preview of the AVCaptureSession (ARKit layer is still in the background)
            self.view.layer.addSublayer(videoPreviewLayer!)
            
            // Focus on the provided coordinate (show focus animation)
            // Programatically focus on point in image
            if let device = captureDevice {
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                    try device.lockForConfiguration()
                    let screenSize = UIScreen.main.bounds.size
                    let focus_x = center.x / screenSize.width
                    let focus_y = center.y / screenSize.height
                    let focusPoint = CGPoint(x: focus_x, y: focus_y)
                    device.focusPointOfInterest = focusPoint
                    // device.focusMode = .continuousAutoFocus
                    device.focusMode = .autoFocus
                    // device.focusMode = .locked
                    device.exposurePointOfInterest = focusPoint
                    device.exposureMode = .continuousAutoExposure
                    device.addObserver(self, forKeyPath: "adjustingFocus", options: NSKeyValueObservingOptions.new, context: nil)
                    device.unlockForConfiguration()
                }
            }
            
            // Show focus animation
            addFocusAnimation(tapLocation: center)
        } catch {
            print(error)
        }
    }
    
    func finishedFocusing() {
        self.removeFocusAnimation()
        // Capture the image
        takePhoto()
    }
    
    func addFocusAnimation(tapLocation: CGPoint) {
        self.focusAnimationBlock = FocusAnimationBlock(tapLocation: tapLocation)
        self.view.addSubview(focusAnimationBlock!)
    }
    
    func removeFocusAnimation() {
        if let animationBlock = self.focusAnimationBlock {
            animationBlock.removeFromSuperview()
            self.focusAnimationBlock = nil
        }
    }
    
    func removeImageCaptureBlock() {
        self.imageCaptureBlock?.removeFromSuperview()
        self.imageCaptureBlock = nil
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let key = keyPath {
            if key == "adjustingFocus" {
                if let changeDict = change {
                    let newVal = changeDict[NSKeyValueChangeKey.newKey] as! Int
                    if newVal == 0 {
                        focusCounter += 1
                        if focusCounter == 2 {
                            self.finishedFocusing()
                            focusCounter = 0
                        }
                    }
                }
            }
        }
    }
    
//    func takeScreenshot(view: UIView) -> UIImage {
//        UIGraphicsBeginImageContext(view.frame.size)
//        videoPreviewLayer.render(in: UIGraphicsGetCurrentContext()!)
//        // view.layer.render(in: UIGraphicsGetCurrentContext()!)
//        let image = UIGraphicsGetImageFromCurrentImageContext()!
//        UIGraphicsEndImageContext()
//        return image
//    }
    
    // New take photo function uses AVCaptureSession
    func takePhoto() {
        if let videoConnection = stillImageOutput.connection(with: .video) {
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.flashMode = .off
            stillImageOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation() {
            if let image = UIImage(data: data) {
                photoTaken(image: image)
            }
        }
    }
    
    func preCropImage(image: UIImage) -> UIImage {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        let heightScaleFactor = image.size.height / screenHeight
        let extraWidth = image.size.width / heightScaleFactor - screenWidth
        
        // Only for iPhone X
        if extraWidth > 0 {
            let sideCropLength = extraWidth / 2
            let cropRectangle = CGRect(x: 0, y: sideCropLength, width: screenHeight, height: screenWidth)
            let preCropped = image.crop(rect: cropRectangle, scaleFactor: heightScaleFactor)
            return preCropped
        }
        
        return image
    }
    
    func photoTaken(image: UIImage) {
        // Perform Pre-crop
        let preCroppedImage = preCropImage(image: image)
        
        // Crop photo based on specified frame
        let screenWidth = UIScreen.main.bounds.width
        let scaleFactor = preCroppedImage.size.width / screenWidth

        // Modify x and y co-ordinates because of the way iOS handles images - rotation happens 90º counter-clockwise
        let newCropRectangle = CGRect(x: self.cropRectangle.minY, y: screenWidth - self.cropRectangle.maxX, width: self.cropRectangle.height, height: self.cropRectangle.width)
        
        let croppedImage = preCroppedImage.crop(rect: newCropRectangle, scaleFactor: scaleFactor)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        UIImageWriteToSavedPhotosAlbum(croppedImage, nil, nil, nil)
        
        // Preview the images
//        let newImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 300, height: 500))
//        newImageView.contentMode = .scaleAspectFit
//        newImageView.image = croppedImage
//        self.view.addSubview(newImageView)
        
        // Feed it into Tesseract and extract text
        tesseract.image = croppedImage
        tesseract.recognize()
        
        let lines = tesseract.recognizedBlocks(by: .textline) as! [G8RecognizedBlock]
        
        if lines.count > 0 {
            // Get origin of first box
//            let firstBoundingBox = lines.first!.boundingBox
//            let firstAdjustedRect = TesseractDimensionsHelper.getFinalBoundingBox(cropRect: self.cropRectangle, boundingBox: firstBoundingBox)
            
            // Get all bounding boxes
            let boundingBoxes = lines.map { $0.boundingBox }
            let combinedBox = TesseractDimensionsHelper.getCombinedBoundingBox(cropRect: self.cropRectangle, boundingBoxes: boundingBoxes)
            
            var textLines = [String]()
            for line in lines {
                textLines.append(line.text)
            }
            
            arHelper.insertPlaneIntoScene(finalBox: combinedBox, lines: textLines)
        }
        
//        for line in lines as! [G8RecognizedBlock] {
//            // Extract coordinates of text
//            let boundingBox = line.boundingBox
//            // Gets us the bounding box for a specific line of text.
//            let adjustedRect = TesseractDimensionsHelper.getFinalBoundingBox(cropRect: self.cropRectangle, boundingBox: boundingBox)
//            // arHelper.insertPlaneIntoScene(finalBox: adjustedRect, line: line.text)
//            if let feature = arHelper.getNearestFeaturePoint(starting: adjustedRect.origin) {
//                print("HALLELUJAH!")
//                arHelper.insertTextIntoRect(rect: adjustedRect, text: line.text, hitResult: feature)
//            }
//        }
        
        print("Recognition Complete")
        
        let tv = UITextView(frame: CGRect(x: 0, y: 0, width: 250, height: 100))
        tv.text = tesseract.recognizedText
        tv.textColor = UIColor.white
        tv.backgroundColor = UIColor.purple
        self.view.addSubview(tv)
        
        // self.processedImageView = newImageView
        self.tesseractTextView = tv
        
        // Bring back sceneView
        
        videoPreviewLayer.removeFromSuperlayer()
        captureSession.stopRunning()
        sceneView.session.run(self.configuration)
        print("We have returned to ARKit")
        
        // Calculate average coordinates/dimensions
        
        // Project back into 3D space
    }
    
    @objc func removeExtraViews() {
        print("Removing extra views")
        if let tv = self.tesseractTextView {
            tv.removeFromSuperview()
            self.tesseractTextView = nil
        }
        
        if let topIV = self.originalImageView {
            topIV.removeFromSuperview()
            self.originalImageView = nil
        }
        
        if let botIV = self.processedImageView {
            botIV.removeFromSuperview()
            self.processedImageView = nil
        }
    }
    
    
    // Come back to improve on this later.
    func preprocessedImage(for tesseract: G8Tesseract!, sourceImage: UIImage!) -> UIImage! {
        // Process photo for Tesseract
        let stillImageFilter = AdaptiveThreshold()
        stillImageFilter.blurRadiusInPixels = 2.0
        var processedImage = sourceImage.filterWithPipeline { input, output in
            input --> stillImageFilter --> output
        }
        processedImage = UIImage(cgImage: processedImage.cgImage!, scale: 1.0, orientation: sourceImage.imageOrientation)
        
        return processedImage
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            self.removeExtraViews()
        }
    }
    
    func addCancelTapRecognizerToIV(imageView: UIImageView) -> Void {
        
        let cancelTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(removeExtraViews))
        imageView.addGestureRecognizer(cancelTapRecognizer)
    }
    
    @IBOutlet var sceneView: ARSCNView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        self.arHelper = ARKitHelper(sceneView: sceneView)
        
        // Test Tesseract Library
        self.tesseract = G8Tesseract(language:"eng")
        tesseract.delegate = self
        
        tesseract.engineMode = .tesseractCubeCombined
        
        tesseract.pageSegmentationMode = .auto
        tesseract.charWhitelist = "abcdefghijklmnopqrstuvwxyz012345789()//.,:;"

    }
    
    func shouldCancelImageRecognitionForTesseract(tesseract: G8Tesseract!) -> Bool {
        return false; // return true if you need to interrupt tesseract before it finishes
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        self.configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(self.configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
