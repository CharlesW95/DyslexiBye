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
    
    // Tesseract Variables
    var tesseract: G8Tesseract!
    
    // ARKit Variables
    var configuration: ARWorldTrackingConfiguration!
    
    @IBOutlet weak var displayImageView: UIImageView!
    
    @IBAction func panGestureRecognized(_ sender: Any) {
        let sender = sender as! UIPanGestureRecognizer
        switch (sender.state) {
            case .began:
                print("BEGAN")
                
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
                        print("Valid area identified")
                        // Start image capture
                        self.cropRectangle = captureBlock.returnFrame()
                        startImageFocus(center: captureBlock.returnCenter())
                    } else {
                        print("Nada")
                    }
                }
            
            default:
                print("OK")
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
    
    @IBAction func firePressed(_ sender: Any) {
        if !firing {
            // Take photo and start image recognition process.
            firing = true
            
//            if let capturedPhoto = takePhoto() {
//                displayImageView.image = capturedPhoto
//            }
            firing = false
        }
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
    
    func photoTaken(image: UIImage) {
        // Crop photo based on specified frame
        let scaleFactor = image.size.width / UIScreen.main.bounds.width
        // Invert x and y co-ordinates because of iOS bug?
        let newCropRectangle = CGRect(x: self.cropRectangle.minY, y: self.cropRectangle.minX, width: self.cropRectangle.height, height: self.cropRectangle.width)
        let croppedImage = image.crop(rect: newCropRectangle, scaleFactor: scaleFactor)
        
        
        
        
        
        // Preview the images
        let newImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 300, height: 500))
        newImageView.contentMode = .scaleAspectFit
        newImageView.image = croppedImage
        self.view.addSubview(newImageView)
        
        
        
        
        // Feed it into Tesseract and extract text
        tesseract.image = croppedImage
        tesseract.recognize()
        
        print(tesseract.recognizedText)
        print("Recognition Complete")
        // Extract coordinates of text
        
        
        
//        let tv = UITextView(frame: CGRect(x: 0, y: 0, width: 250, height: 400))
//        tv.text = tesseract.recognizedText
//        tv.textColor = UIColor.white
//        tv.backgroundColor = UIColor.black
//        self.view.addSubview(tv)
        
        // Bring back sceneView
        
        videoPreviewLayer.removeFromSuperlayer()
        captureSession.stopRunning()
        sceneView.session.run(self.configuration)
        print("We have returned to ARKit")
        
        
        
        // Calculate average coordinates/dimensions
        
        // Project back into 3D space
    }
    
    func preprocessedImage(for tesseract: G8Tesseract!, sourceImage: UIImage!) -> UIImage! {
        // Process photo for Tesseract
        let stillImageFilter = AdaptiveThreshold()
        stillImageFilter.blurRadiusInPixels = 4.0
        var processedImage = sourceImage.filterWithPipeline { input, output in
            input --> stillImageFilter --> output
        }
        processedImage = UIImage(cgImage: processedImage.cgImage!, scale: 1.0, orientation: sourceImage.imageOrientation)
        
        print("Size comparison:")
        print(sourceImage.size)
        print(processedImage.size)
        
        let iv = UIImageView(frame: CGRect(x: 0, y: 300, width: 300, height: 500))
        iv.contentMode = .scaleAspectFit
        iv.image = processedImage
        self.view.addSubview(iv)
        
        return processedImage
    }
    
    @IBOutlet var sceneView: ARSCNView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Test Tesseract Library
        self.tesseract = G8Tesseract(language:"eng")
        tesseract.delegate = self
        
        tesseract.engineMode = .tesseractCubeCombined
        
        tesseract.pageSegmentationMode = .auto
        tesseract.charWhitelist = "abcdefghijklmnopqrstuvwxyz012345789()//.,:;"

        // Create a new scene
        // let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        // sceneView.scene = scene
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
