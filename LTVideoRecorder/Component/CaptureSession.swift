//
//  CaptureSession.swift
//  LTVideoRecorder
//
//  Created by leo on 2018/12/29.
//  Copyright © 2018 ltebean. All rights reserved.
//

import AVFoundation
import Async

class CaptureSession: NSObject {
    
    let sessionQueue: DispatchQueue = DispatchQueue(label: "session queue", attributes: [])
    let videoOutputQueue: DispatchQueue = DispatchQueue(label: "video output queue", attributes: [])
    let audioOutputQueue: DispatchQueue = DispatchQueue(label: "audio output queue", attributes: [])
    
    let session = AVCaptureSession()
    
    var videoDevice: AVCaptureDevice!
    var videoInput: AVCaptureDeviceInput!
    var videoOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
    var videoConnection: AVCaptureConnection!
    
    var audioInput: AVCaptureDeviceInput!
    var audioOutput: AVCaptureAudioDataOutput = AVCaptureAudioDataOutput()
    var audioConnection: AVCaptureConnection!
    
    var isFrontCamera = true
    var loaded = false
    
    var onVideoBuffer: ((_ buffer: CMSampleBuffer) -> ())!
    var onAudioBuffer: ((_ buffer: CMSampleBuffer) -> ())!
    
    override init() {
        super.init()
    }
    
    func setup() {
        guard !loaded else { return }
        loaded = true
        Async.custom(queue: sessionQueue) {
            self.session.sessionPreset = AVCaptureSession.Preset.hd1280x720
        
            // video
            self.videoDevice = AVCaptureDevice.backCamera()
            self.videoInput = try! AVCaptureDeviceInput(device: self.videoDevice)
            self.videoOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)
            
            self.videoOutput.videoSettings = [
                String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_32BGRA),
                String(kCVPixelBufferWidthKey) : Int(720),
                String(kCVPixelBufferHeightKey) : Int(1280),
                String(kCVPixelFormatOpenGLESCompatibility) : kCFBooleanTrue
            ]
            self.session.addInput(self.videoInput)
            self.session.addOutput(self.videoOutput)
            self.videoConnection = self.videoOutput.connection(with: AVMediaType.video)
            self.videoConnection!.videoOrientation = .portrait
//            self.videoConnection!.isVideoMirrored = self.isFrontCamera
            
            // audio
            let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)!
            self.audioInput = try! AVCaptureDeviceInput(device: audioDevice)
            self.audioOutput.setSampleBufferDelegate(self, queue: self.audioOutputQueue)
            self.session.addInput(self.audioInput)
            self.session.addOutput(self.audioOutput)
            self.audioConnection = self.audioOutput.connection(with: AVMediaType.audio)
        }
    }
    
    func requestAccess(completion: @escaping ((_ granted: Bool) -> ())) {
        var counter = 0
        var videoGranted = false
        var audioGranted = false
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { granted in
            counter += 1
            videoGranted = granted
            if counter == 2 {
                completion(videoGranted && audioGranted)
            }
        })
        AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: { granted in
            counter += 1
            audioGranted = granted
            if counter == 2 {
                completion(videoGranted && audioGranted)
            }
        })
    }
    
    func startRunning() {
        Async.custom(queue: sessionQueue) {
            self.session.startRunning()
        }
    }
    
    func stopRunning() {
        Async.custom(queue: sessionQueue) {
            self.session.stopRunning()
        }
    }
    
    func switchCamera() {
        Async.custom(queue: sessionQueue) {
            self.session.beginConfiguration()
            self.session.removeInput(self.videoInput)
            self.videoDevice = self.isFrontCamera ? AVCaptureDevice.backCamera() : AVCaptureDevice.frontCamera()
            self.isFrontCamera = !self.isFrontCamera
            self.videoInput = try! AVCaptureDeviceInput(device: self.videoDevice)
            self.session.addInput(self.videoInput)
            self.videoConnection = self.videoOutput.connection(with: AVMediaType.video)
            self.videoConnection!.videoOrientation = .portrait
            self.videoConnection!.isVideoMirrored = self.isFrontCamera
            self.session.commitConfiguration()
        }
    }
    
}

extension CaptureSession: AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection == videoConnection {
            onVideoBuffer(sampleBuffer)
        }
        else if connection == audioConnection {
            onAudioBuffer(sampleBuffer)
        }
    }
    
    
}
