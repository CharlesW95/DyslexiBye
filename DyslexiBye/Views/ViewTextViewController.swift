//
//  ViewTextViewController.swift
//  DyslexiBye
//
//  Created by Charles Wong on 12/5/17.
//  Copyright © 2017 Charles Wong. All rights reserved.
//

import UIKit

class ViewTextViewController: UIViewController {
    
    @IBOutlet weak var mainTextView: UITextView!
    @IBOutlet weak var closeButton: UIButton!

    var text: String!
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        insertContentIntoTextView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func setupView() {
        self.view.backgroundColor = Colors.backgroundYellow
        setupTextView()
    }
    
    func setupTextView() {
        // Style
        mainTextView.font = UIFont(name: "Dyslexie-Regular", size: 14.0)
        mainTextView.textColor = Colors.textBlue
        mainTextView.backgroundColor = UIColor.clear
        mainTextView.isEditable = false
    }
    
    func insertContentIntoTextView() {
        mainTextView.text = self.text
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
