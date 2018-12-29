//
//  VideoProcessor.swift
//  LTVideoRecorder
//
//  Created by leo on 2018/12/29.
//  Copyright © 2018 ltebean. All rights reserved.
//

import Foundation

import AVFoundation
import CoreImage
import UIKit

class VideoProcessor {
    
    let ciContext = CIContext()

    private var filters: [Filter] = []

    init() {
        filters = [
            PlainFilter(),
            VignetteFilter(),
            PixellateFilter(scale: 30),
            SketchFilter(),
            BlurFilter(radius: 20),
            ComicEffectFilter(),
            StarBurstFilter(),
            BulgingEyesFilter(ciContext: self.ciContext)
        ]
    }

    private var currentFilterIndex = 0

    func useFilter(ofIndex index: Int) {
        currentFilterIndex = index
    }

    func useNextFilter() {
        if (currentFilterIndex < filters.count - 1) {
            currentFilterIndex = currentFilterIndex + 1
        } else {
            currentFilterIndex = 0
        }
    }

    func usePreviousFilter() {
        if (currentFilterIndex > 0) {
            currentFilterIndex = currentFilterIndex - 1
        } else {
            currentFilterIndex = filters.count - 1
        }
    }

    func processWithFilter(image: CIImage) -> CIImage {
        return filters[currentFilterIndex].process(image: image)
    }
    
    func process(image: CIImage, withOverlay overlay: UIImage) -> CIImage {
        let overlayImage = CIImage(cgImage: overlay.resize(toSize: image.extent.width).cgImage!)
        return image.applyingFilter("CISourceOverCompositing", parameters: [
            "inputBackgroundImage": image,
            "inputImage": overlayImage
        ])
    }
    
}
