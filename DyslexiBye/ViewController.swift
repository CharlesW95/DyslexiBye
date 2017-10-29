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

class ViewController: UIViewController, ARSCNViewDelegate, G8TesseractDelegate {
    
    // App State
    var firing = false
    var focusCounter = 0
    
    // AVFoundation Variables
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    @IBOutlet weak var displayImageView: UIImageView!
    @IBAction func longPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            
            // Hide the sceneView temporarily
            sceneView.session.pause() // Pause the ARSession
            
            // Set up ARCaptureSession
            let captureDevice = AVCaptureDevice.default(for: .video)
            
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice!)
                captureSession = AVCaptureSession()
                captureSession?.addInput(input)
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                videoPreviewLayer?.videoGravity = .resizeAspectFill
                videoPreviewLayer?.frame = self.view.layer.bounds
                print("Starting process...")
                captureSession?.startRunning()
                
                // Show the preview of the AVCaptureSession (ARKit layer is still in the background)
                self.view.layer.addSublayer(videoPreviewLayer!)
                
                // Focus on the provided coordinate (show focus animation)
                let tapLocation = sender.location(in: self.view)
                // Programatically focus on point in image
                if let device = captureDevice {
                    if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                        try device.lockForConfiguration()
                        
                        let screenSize = UIScreen.main.bounds.size
                        let focus_x = tapLocation.x / screenSize.width
                        let focus_y = tapLocation.y / screenSize.height
                        let focusPoint = CGPoint(x: focus_x, y: focus_y)
                        print(focusPoint)
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
                
                
                // Capture the image
                
                // Feed it into Tesseract and extract text
                
                // Extract coordinates of text
                
                // Bring back sceneView
                
                // Calculate average coordinates/dimensions
                
                // Project back into 3D space
                
            } catch {
                print(error)
            }
            
            
            
            
        }
        
    }
    
    @IBAction func firePressed(_ sender: Any) {
        if !firing {
            // Take photo and start image recognition process.
            firing = true
            
            
            
            if let capturedPhoto = takePhoto() {
                displayImageView.image = capturedPhoto
            }
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
                            print("Job done")
                            focusCounter = 0
                        }
                    }
                }
            }
        }
    }
    
    
    // Takes a camera image and returns it
    func takePhoto() -> UIImage? {
        if let pixelBuffer = sceneView.session.currentFrame?.capturedImage {
            let extractedImage = CIImage(cvPixelBuffer: pixelBuffer)
            let tempContext = CIContext()
            if let videoImage = tempContext.createCGImage(extractedImage,
                                                       from: CGRect(x: 0, y: 0,
                                                                    width: CVPixelBufferGetWidth(pixelBuffer),
                                                                    height: CVPixelBufferGetHeight(pixelBuffer))) {
                print("Success")
                return UIImage(cgImage: videoImage)
            }
        }
        
        return nil
    }
    
    @IBOutlet var sceneView: ARSCNView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Test Tesseract Library
        let tesseract:G8Tesseract = G8Tesseract(language:"eng")
        tesseract.delegate = self
        
        tesseract.engineMode = .tesseractCubeCombined
        
        tesseract.pageSegmentationMode = .auto
        // tesseract.charWhitelist = "abcdefghijklmnopqrstuvwxyz012345789"


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
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
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
