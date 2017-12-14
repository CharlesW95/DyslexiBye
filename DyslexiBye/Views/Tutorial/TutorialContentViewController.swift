//
//  TutorialContentViewController.swift
//  DyslexiBye
//
//  Created by Charles Wong on 12/10/17.
//  Copyright © 2017 Charles Wong. All rights reserved.
//

import UIKit

class TutorialContentViewController: UIViewController {
    
    var pageIndex: Int!
    var pageDescription: String!
    var imageName: String!
    
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var tutorialImageView: UIImageView!
    @IBOutlet weak var tutorialTextView: UITextView!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        let pvc = self.parent as! TutorialPageViewController
        pvc.dismiss(animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupApperance()
        setContent()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupApperance() {
        self.view.backgroundColor = Colors.backgroundYellow
        
        // Style Label
        progressLabel.textAlignment = .center
        progressLabel.textColor = Colors.textBlue
        progressLabel.font = UIFont(name: "Dyslexie-Regular", size: 20.0)
        
        // Style Image
        tutorialImageView.contentMode = .scaleAspectFit
        
        // Style TextView
        tutorialTextView.backgroundColor = UIColor.clear
        tutorialTextView.textAlignment = .center
        tutorialTextView.textColor = Colors.textBlue
        tutorialTextView.font = UIFont(name: "Dyslexie-Regular", size: 16.0)
        tutorialTextView.isEditable = false
        
        // Style Button
        closeButton.setTitle("Done", for: .normal)
        closeButton.setTitleColor(UIColor.white, for: .normal)
        closeButton.titleLabel?.font = UIFont(name: "Dyslexie-Regular", size: 16.0)
        closeButton.tintColor = UIColor.white
        closeButton.backgroundColor = Colors.textBlue
        closeButton.layer.cornerRadius = 10.0
    }
    
    func setContent() {
        progressLabel.text = "\(pageIndex + 1) / 3"
        tutorialImageView.image = UIImage(named: imageName)
        tutorialTextView.text = pageDescription
    }

}
