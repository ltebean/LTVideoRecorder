//
//  Filter.swift
//  LTVideoRecorder
//
//  Created by leo on 2018/12/29.
//  Copyright © 2018 ltebean. All rights reserved.
//

import AVFoundation
import CoreImage

protocol Filter {
    func process(image: CIImage) -> CIImage
}

struct PlainFilter: Filter {
    func process(image: CIImage) -> CIImage {
        return image
    }
}

struct PixellateFilter: Filter {
    
    let filter = CIFilter(name: "CIPixellate")!
    
    init(scale: Int) {
        filter.setValue(scale, forKey: kCIInputScaleKey)
    }
    
    func process(image: CIImage) -> CIImage {
        filter.setValue(image, forKey: "inputImage")
        return filter.outputImage!.cropped(to: image.extent)
    }
}

struct BlurFilter: Filter {
    
    let filter = CIFilter(name: "CIGaussianBlur")!
    
    init(radius: Int) {
        filter.setValue(radius, forKey: "inputRadius")
    }
    
    func process(image: CIImage) -> CIImage {
        filter.setValue(image, forKey: "inputImage")
        return filter.outputImage!.cropped(to: image.extent)
    }
}

struct SketchFilter: Filter {
    
    let filter = CIFilter(name: "CILineOverlay")!
    let bgFilter = CIFilter(name: "CIConstantColorGenerator")!
    let overlayFilter = CIFilter(name: "CISourceOverCompositing")!
    let bgImage: CIImage
    init() {
        filter.setValue(50.0, forKey: "inputContrast")
        filter.setValue(0.19, forKey: "inputNRNoiseLevel")
        filter.setValue(0.7, forKey: "inputNRSharpness")
        filter.setValue(0.2, forKey: "inputEdgeIntensity")
        filter.setValue(0.04, forKey: "inputThreshold")
        
        let bgColor = CIColor(red: 1, green: 1, blue: 1)
        bgFilter.setValue(bgColor, forKey: "inputColor")
        bgImage = bgFilter.outputImage!
    }
    
    func process(image: CIImage) -> CIImage {
        filter.setValue(image, forKey: "inputImage")
        overlayFilter.setValue(filter.outputImage!, forKey: "inputImage")
        overlayFilter.setValue(bgImage.cropped(to: image.extent), forKey: "inputBackgroundImage")
        return overlayFilter.outputImage!
    }
}

struct ComicEffectFilter: Filter {
    
    let filter = CIFilter(name: "CIComicEffect")!
    
    func process(image: CIImage) -> CIImage {
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage!
    }
}

struct VignetteFilter: Filter {
    
    let filter = CIFilter(name: "CIVignette")!
    init() {
        filter.setValue(1, forKey: "inputIntensity")
        filter.setValue(2, forKey: "inputRadius")
    }
    func process(image: CIImage) -> CIImage {
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage!
    }
}

struct BeautyFilter: Filter {
    
    let filter = CIFilter(name: "CIGloom")!
    init() {
        filter.setValue(0.7, forKey: "inputIntensity")
        filter.setValue(10, forKey: "inputRadius")
    }
    func process(image: CIImage) -> CIImage {
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage!.cropped(to: image.extent)
    }
}

struct PhotoEffectTransferFilter: Filter {
    
    let filter = CIFilter(name: "CIPhotoEffectTransfer")!
    
    func process(image: CIImage) -> CIImage {
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage!
    }
}

struct PhotoEffectNoirFilter: Filter {
    
    let filter = CIFilter(name: "CIPhotoEffectNoir")!
    
    func process(image: CIImage) -> CIImage {
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage!
    }
}

struct StarBurstFilter: Filter {
    
    let thresholdFilter = ThresholdFilter()
    
    func process(image: CIImage) -> CIImage {
        thresholdFilter.inputImage = image
        let output = thresholdFilter.outputImage!
        
        let blurImageOne = output
            .applyingFilter("CIMotionBlur",
                            parameters: [
                                kCIInputRadiusKey: 30,
                                kCIInputAngleKey: M_PI_4])
            .cropped(to: image.extent)
        
        let blurImageTwo = output
            .applyingFilter("CIMotionBlur",
                            parameters: [
                                kCIInputRadiusKey: 30,
                                kCIInputAngleKey: M_PI_4 + M_PI_2])
            .cropped(to: image.extent)
        
        let starBurstImage = blurImageOne
            .applyingFilter("CIAdditionCompositing",
                            parameters: [
                                kCIInputBackgroundImageKey: blurImageTwo])
        
        return image
            .applyingFilter("CIAdditionCompositing",
                            parameters: [
                                kCIInputBackgroundImageKey: starBurstImage])
        
    }
}

class ThresholdFilter: CIFilter {
    var inputImage : CIImage?
    var kernel = CIColorKernel(source: try! String(contentsOf: Bundle.main.url(forResource: "threshold", withExtension: "txt")!, encoding: String.Encoding.utf8))
    override var outputImage : CIImage! {
        guard let inputImage = inputImage, let kernel = kernel else {
            return nil
        }
        let extent = inputImage.extent
        let arguments = [ inputImage ] as [Any]
        return kernel.apply(extent: extent, roiCallback: { index, rect -> CGRect in
            return rect
        }, arguments: arguments)
    }
}


struct BulgingEyesFilter: Filter {
    
    let detector: CIDetector
    init(ciContext: CIContext) {
        let options: [String: Any] = [
            CIDetectorAccuracy: CIDetectorAccuracyHigh,
            CIDetectorTracking: true
        ]
        detector = CIDetector(ofType:CIDetectorTypeFace, context: ciContext,
                              options: options)!
    }
    
    func process(image: CIImage) -> CIImage {
        if let features = detector.features(in: image).first as? CIFaceFeature, features.hasLeftEyePosition && features.hasRightEyePosition {
            let eyeDistance = features.leftEyePosition.distanceTo(point: features.rightEyePosition)
            return image
                .applyingFilter("CIBumpDistortion",
                                parameters: [
                                    kCIInputRadiusKey: eyeDistance / 1.25,
                                    kCIInputScaleKey: 0.5,
                                    kCIInputCenterKey: features.leftEyePosition.toCIVector()])
                .cropped(to: image.extent)
                .applyingFilter("CIBumpDistortion",
                                parameters: [
                                    kCIInputRadiusKey: eyeDistance / 1.25,
                                    kCIInputScaleKey: 0.5,
                                    kCIInputCenterKey: features.rightEyePosition.toCIVector()])
                .cropped(to: image.extent)
            
        } else {
            return image
        }
        
    }
}

//struct GlassesFilter: Filter {
//
//    let detector: CIDetector
//    init(ciContext: CIContext) {
//        let options: [String: Any] = [
//            CIDetectorAccuracy: CIDetectorAccuracyHigh,
//            CIDetectorTracking: true
//        ]
//        detector = CIDetector(ofType:CIDetectorTypeFace, context: ciContext,
//                              options: options)!
//    }
//
//    let glasses = R.image.picGlasses()!
//    let hat = R.image.picHat()!
//
//    let overlayFilter = CIFilter(name: "CISourceOverCompositing")!
//
//    func process(image: CIImage) -> CIImage {
//        if let features = detector.features(in: image).first as? CIFaceFeature, features.hasLeftEyePosition && features.hasRightEyePosition {
//            let bounds = features.bounds
//
//            let leftEyePosition = features.leftEyePosition
//            let rightEyePosition = features.rightEyePosition
//
//            let angle = atan((rightEyePosition.y - leftEyePosition.y) / (rightEyePosition.x - leftEyePosition.x))
//            //            let y = (leftEyePosition.y + rightEyePosition.y) / 2
//
//            let resizedGlasses = glasses.resize(toSize: bounds.width)
//            var glassesOverlay = CIImage(cgImage: resizedGlasses.cgImage!)
//            var glassesTransform = CGAffineTransform(translationX: bounds.origin.x, y: leftEyePosition.y - resizedGlasses.size.height / 2)
//            glassesTransform = glassesTransform.rotated(by: angle)
//            glassesOverlay = glassesOverlay.applying(glassesTransform)
//
//            let resizedHat = hat.resize(toSize: bounds.width * 2)
//            var hatOverlay = CIImage(cgImage: resizedHat.cgImage!)
//            var hatTransform = CGAffineTransform(translationX: bounds.origin.x - resizedGlasses.size.width / 2 , y: leftEyePosition.y + bounds.height / 8)
//            hatTransform = hatTransform.rotated(by: angle)
//            hatOverlay = hatOverlay.applying(hatTransform)
//
//            let output = image.applyingFilter("CISourceOverCompositing", withInputParameters: [
//                "inputBackgroundImage": image,
//                "inputImage": glassesOverlay
//                ])
//
//            return output.applyingFilter("CISourceOverCompositing", withInputParameters: [
//                "inputBackgroundImage": output,
//                "inputImage": hatOverlay
//                ]).cropping(to: image.extent)
//
//
//        } else {
//            return image
//        }
//
//    }
//}

extension CGPoint {
    
    func distanceTo(point: CGPoint) -> CGFloat {
        return hypot(self.x - point.x, self.y - point.y)
    }
    
    func toCIVector() -> CIVector {
        return CIVector(x: self.x, y: self.y)
    }
}


