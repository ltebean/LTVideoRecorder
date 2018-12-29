//
//  VideoEncoder.swift
//  GhostFace
//
//  Created by leo on 16/12/10.
//  Copyright © 2016年 CaowuTechnology. All rights reserved.
//

import UIKit
import AVFoundation

public enum VideoEncoderEncoderSettings: String {
    case Preset640x480
    case Preset960x540
    case Preset1280x720
    case Preset1920x1080
    case Preset3840x2160
    case Unknow
    
    private func avFoundationPresetString() -> String? {
        switch self {
        case .Preset640x480: return AVOutputSettingsPreset.preset640x480.rawValue
        case .Preset960x540: return AVOutputSettingsPreset.preset960x540.rawValue
        case .Preset1280x720: return AVOutputSettingsPreset.preset1280x720.rawValue
        case .Preset1920x1080: return AVOutputSettingsPreset.preset1920x1080.rawValue
        case .Preset3840x2160:
            if #available(iOS 9.0, *) {
                return AVOutputSettingsPreset.preset3840x2160.rawValue
            }
            else {
                return nil
            }
        case .Unknow: return nil
        }
    }
    
    func configuration() -> AVOutputSettingsAssistant? {
        if let presetSetting = self.avFoundationPresetString() {
            return AVOutputSettingsAssistant(preset: AVOutputSettingsPreset(rawValue: presetSetting))
        }
        return nil
    }
    
    public static func availableFocus() -> [VideoEncoderEncoderSettings] {
        return AVOutputSettingsAssistant.availableOutputSettingsPresets().map {
            if #available(iOS 9.0, *) {
                switch $0 {
                case AVOutputSettingsPreset.preset640x480: return .Preset640x480
                case AVOutputSettingsPreset.preset960x540: return .Preset960x540
                case AVOutputSettingsPreset.preset1280x720: return .Preset1280x720
                case AVOutputSettingsPreset.preset1920x1080: return .Preset1920x1080
                case AVOutputSettingsPreset.preset3840x2160: return .Preset3840x2160
                default: return .Unknow
                }
            }
            else {
                switch $0 {
                case AVOutputSettingsPreset.preset640x480: return .Preset640x480
                case AVOutputSettingsPreset.preset960x540: return .Preset960x540
                case AVOutputSettingsPreset.preset1280x720: return .Preset1280x720
                case AVOutputSettingsPreset.preset1920x1080: return .Preset1920x1080
                default: return .Unknow
                }
            }
        }
    }
    
    public func description() -> String {
        switch self {
        case .Preset640x480: return "Preset 640x480"
        case .Preset960x540: return "Preset 960x540"
        case .Preset1280x720: return "Preset 1280x720"
        case .Preset1920x1080: return "Preset 1920x1080"
        case .Preset3840x2160: return "Preset 3840x2160"
        case .Unknow: return "Preset Unknow"
        }
    }
}

extension UIDevice {
    static func orientationTransformation() -> CGFloat {
        switch UIDevice.current.orientation {
        case .portrait: return 0
        case .portraitUpsideDown: return CGFloat(M_PI / 4)
        case .landscapeRight: return CGFloat(M_PI)
        case .landscapeLeft: return CGFloat(M_PI * 2)
        default: return 0
        }
    }
}

class VideoWriter {
    
    var shouldOptimizeForNetworkUse = true
    
    private var assetWriter: AVAssetWriter!
    private var videoInputWriter: AVAssetWriterInput!
    private var audioInputWriter: AVAssetWriterInput!
    private var firstFrame = false
    private var startTime: CMTime!
    private var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?

    lazy var presetSettingEncoder: AVOutputSettingsAssistant? = {
        return VideoEncoderEncoderSettings.Preset1280x720.configuration()
    }()
    
    private func initVideoWriter(_ url: URL) {
        self.firstFrame = false
        guard let presetSettingEncoder = self.presetSettingEncoder else {
            print("[Camera engine] presetSettingEncoder = nil")
            return
        }
        
        do {
            self.assetWriter = try AVAssetWriter(url: url, fileType: AVFileType.mp4)
        }
        catch {
            fatalError("error init assetWriter")
        }
        
        assetWriter.shouldOptimizeForNetworkUse = shouldOptimizeForNetworkUse
        
        var videoOutputSettings = presetSettingEncoder.videoSettings!
        let audioOutputSettings = presetSettingEncoder.audioSettings
        
        let settings:[String: Any] = [
            String(AVVideoAverageBitRateKey): Int(512000),
            String(AVVideoExpectedSourceFrameRateKey): Int(30)
        ]
        videoOutputSettings[String(AVVideoCompressionPropertiesKey)] = settings

        
        guard self.assetWriter.canApply(outputSettings: videoOutputSettings, forMediaType: AVMediaType.video) else {
            fatalError("Negative [VIDEO] : Can't apply the Output settings...")
        }
        guard self.assetWriter.canApply(outputSettings: audioOutputSettings, forMediaType: AVMediaType.audio) else {
            fatalError("Negative [AUDIO] : Can't apply the Output settings...")
        }
        
        self.videoInputWriter = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
        self.videoInputWriter.expectsMediaDataInRealTime = true
        self.videoInputWriter.transform = CGAffineTransform(rotationAngle: UIDevice.orientationTransformation())
        
        self.audioInputWriter = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
        self.audioInputWriter.expectsMediaDataInRealTime = true
        
        if self.assetWriter.canAdd(self.videoInputWriter) {
            self.assetWriter.add(self.videoInputWriter)
        }
        if self.assetWriter.canAdd(self.audioInputWriter) {
            self.assetWriter.add(self.audioInputWriter)
        }
        let sourcePixelBufferAttributesDictionary: [String : Any] = [
            String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_32BGRA),
            String(kCVPixelBufferWidthKey) : Int(720),
            String(kCVPixelBufferHeightKey) : Int(1280),
            String(kCVPixelFormatOpenGLESCompatibility) : kCFBooleanTrue
        ]
        
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInputWriter, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)

    }
    
    func startWriting(_ url: URL) {
        self.firstFrame = false
        self.startTime = CMClockGetTime(CMClockGetHostTimeClock())
        self.initVideoWriter(url)
    }
    
    func stopWriting(_ blockCompletion: @escaping (_ url: URL) -> ()) {
        self.videoInputWriter.markAsFinished()
        self.audioInputWriter.markAsFinished()
        
        self.assetWriter.finishWriting { () -> Void in
            blockCompletion(self.assetWriter.outputURL)
        }
    }
    
    func appendPixelBuffer(pixelBuffer: CVPixelBuffer, time: CMTime) {
        self.firstFrame = true
        if self.assetWriter.status == AVAssetWriter.Status.unknown {
            let startTime = time
            self.assetWriter.startWriting()
            self.assetWriter.startSession(atSourceTime: startTime)
        }
        if self.videoInputWriter.isReadyForMoreMediaData {
            let _ = self.assetWriterPixelBufferInput?.append(pixelBuffer, withPresentationTime: time)
        }
    }
    
    
    func appendAudioBuffer(_ sampleBuffer: CMSampleBuffer!) {
        if !self.firstFrame {
            return
        }
        self.firstFrame = true
        if CMSampleBufferDataIsReady(sampleBuffer) {
            if self.assetWriter.status == AVAssetWriter.Status.unknown {
                let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                self.assetWriter.startWriting()
                self.assetWriter.startSession(atSourceTime: startTime)
            }
            
            if self.audioInputWriter.isReadyForMoreMediaData {
                self.audioInputWriter.append(sampleBuffer)
            }
            
        }
    }
    
    func progressCurrentBuffer(_ sampleBuffer: CMSampleBuffer) -> Float64 {
        let currentTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let currentTime = CMTimeGetSeconds(CMTimeSubtract(currentTimestamp, self.startTime))
        return currentTime
    }
}
