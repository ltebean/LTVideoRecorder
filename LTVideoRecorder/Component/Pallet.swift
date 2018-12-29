//
//  Pallet.swift
//  GhostFace
//
//  Created by leo on 16/12/14.
//  Copyright © 2016年 CaowuTechnology. All rights reserved.
//

import UIKit

@IBDesignable
class Pallet: XibBasedView {
    
    @IBOutlet var buttons: [DesignableButton]!
    
    let highlightColor = UIColor(hex: 0xdddddd)
    
    var onColorSelected: ((_ color: UIColor) -> ())?
    
    @IBAction func colorButtonPressed(_ sender: DesignableButton) {
        
        for button in buttons {
            if button == sender {
                button.borderColor = highlightColor
            } else {
                button.borderColor = UIColor.clear
            }
        }
        onColorSelected?(sender.backgroundColor!)
    }
    
}
