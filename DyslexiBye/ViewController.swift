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
import TesseractOCR

class ViewController: UIViewController, ARSCNViewDelegate, G8TesseractDelegate {

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
        
        let im = UIImage(named: "Test")
        print("The image follows:")
        print(im)
        
        tesseract.image = im!
        tesseract.recognize()
        
        print("Before")
        print(tesseract.recognizedText)
        print("After")

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
