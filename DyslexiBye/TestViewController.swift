//
//  TestViewController.swift
//  DyslexiBye
//
//  Created by Charles Wong on 10/15/17.
//  Copyright © 2017 Charles Wong. All rights reserved.
//

import UIKit
import TesseractOCR

class TestViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var displayImageView: UIImageView!
    @IBOutlet weak var displayTextView: UITextView!
    
    @IBAction func uploadPressed(_ sender: Any) {
        // Launch a pickerview
        let imagePickerAS = UIAlertController(title: "Choose Image", message: "Select an Option", preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraButton = UIAlertAction(title: "Take Photo", style: .default, handler: { (action: UIAlertAction) -> Void in
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera
                self.present(imagePicker, animated: true, completion: nil)
            })
            imagePickerAS.addAction(cameraButton)
        }
        
        let libraryButton = UIAlertAction(title: "Choose Existing", style: .default, handler: { (alert) -> Void in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
            
        })
        
        imagePickerAS.addAction(libraryButton)
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (alert) -> Void in
        })
        
        imagePickerAS.addAction(cancelButton)
        
        present(imagePickerAS, animated: true, completion: nil)
    }
    
    func scaleImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
        
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        var scaleFactor: CGFloat
        
        if image.size.width > image.size.height {
            scaleFactor = image.size.height / image.size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = image.size.width / image.size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        let rect = CGRect(x: 0, y: 0, width: scaledSize.width, height: scaledSize.height)
        image.draw(in: rect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let selectedPhoto = info[UIImagePickerControllerOriginalImage] as! UIImage
        let scaledImage = scaleImage(image: selectedPhoto, maxDimension: 640)
        
        dismiss(animated: true, completion: {
            self.performImageRecognition(image: scaledImage)
        })
    }
    
    func performImageRecognition(image: UIImage) {
        // 1
        let tesseract: G8Tesseract = G8Tesseract(language:"eng")
        // 3
        tesseract.engineMode = .tesseractCubeCombined
        // 4
        tesseract.pageSegmentationMode = .auto
        
        // 5
        tesseract.maximumRecognitionTime = 60.0
        // 6
        tesseract.image = image.g8_blackAndWhite()
        tesseract.recognize()
        // 7
        displayTextView.text = tesseract.recognizedText
        // displayTextView.editable = true
        
        print("Done!")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
