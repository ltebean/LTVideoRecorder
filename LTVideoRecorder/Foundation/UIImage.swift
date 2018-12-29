//
//  UIImage.swift
//  LTVideoRecorder
//
//  Created by leo on 2018/12/29.
//  Copyright © 2018 ltebean. All rights reserved.
//

import UIKit

extension UIImage {
    
    func resize(toSize newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / size.width
        let newHeight = size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
