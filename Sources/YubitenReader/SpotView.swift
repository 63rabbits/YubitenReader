//
//  SpotView.swift
//
//  Created by 63rabbits goodman on 2024/02/23.
//

import UIKit

class SpotView : UIView {

    var InitialPosition = CGPoint.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        initCommon()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initCommon()
    }

    // BUG: touchesEnded may not be called when repeatedly tapping with multiple fingers. →Spot remains.
    // Fix: It seems that the event was stolen by the displayed Spot.
    //          -> Solved by adding isUserInteractionEnabled = false to Spot View.
    func initCommon() {
        isUserInteractionEnabled = false
        backgroundColor = UIColor.lightGray
    }

    override var bounds: CGRect {
        get { return super.bounds }
        set {
            super.bounds = newValue
            // Update the corner radius when the bounds change.
            layer.cornerRadius = newValue.size.width / 2.0
        }
    }

}


