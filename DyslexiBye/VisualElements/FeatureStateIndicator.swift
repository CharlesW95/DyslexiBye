//
//  FeatureStateIndicator.swift
//  DyslexiBye
//
//  Created by Charles Wong on 12/5/17.
//  Copyright © 2017 Charles Wong. All rights reserved.
//

import UIKit

class FeatureStateIndicator: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    var featureState: FeatureState!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupApperance()
    }
    
    func setupApperance() {
        self.layer.cornerRadius = self.frame.width/2
        updateState(state: .notReady)
    }
    
    func updateState(state: FeatureState) {
        self.featureState = state
        switch (self.featureState) {
        case .ready:
            self.backgroundColor = Colors.featuresReadyGreen
        case .notReady:
            self.backgroundColor = Colors.featuresNotReadyRed
        default:
            return
        }
    }
}
