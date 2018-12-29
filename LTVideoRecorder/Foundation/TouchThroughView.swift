//
//  TouchThroughView.swift
//  GhostFace
//
//  Created by ltebean on 3/21/17.
//  Copyright © 2017 CaowuTechnology. All rights reserved.
//

import UIKit

class TouchThroughView: UIView {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == self {
            return nil
        } else {
            return view
        }
    }

}
