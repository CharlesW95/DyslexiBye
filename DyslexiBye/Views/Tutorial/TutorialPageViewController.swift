//
//  TutorialPageViewController.swift
//  DyslexiBye
//
//  Created by Charles Wong on 12/10/17.
//  Copyright © 2017 Charles Wong. All rights reserved.
//

import UIKit

class TutorialPageViewController: UIPageViewController, UIPageViewControllerDataSource {
    
    // Content options
    final let tutorialTexts = ["Wait for the calibration light to turn green.", "Draw a box around the text you'd like to capture, by dragging your finger across the screen.", "Wait for the results to appear! Waiting for the calibration light to turn green again helps ensure the text stays in place."]
    final let imageNames = ["tutorial1", "tutorial2", "tutorial3"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        
        self.setViewControllers([getViewControllerAtIndex(index: 0)], direction: .forward, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let vc = viewController as! TutorialContentViewController
        if let index = vc.pageIndex {
            if index == self.tutorialTexts.count - 1 {
                return nil
            }
            return getViewControllerAtIndex(index: index + 1)
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let vc = viewController as! TutorialContentViewController
        if let index = vc.pageIndex {
            if index == 0 {
                return nil
            }
            return getViewControllerAtIndex(index: index - 1)
        }
        return nil
    }
    
    func getViewControllerAtIndex(index: Int) -> TutorialContentViewController {
        // Instantiate tutorial content
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "tutorialContentViewController") as! TutorialContentViewController
        vc.pageIndex = index
        vc.pageDescription = tutorialTexts[index]
        vc.imageName = imageNames[index]
        return vc
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
