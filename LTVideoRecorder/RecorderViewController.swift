//
//  RecorderViewController.swift
//  LTVideoRecorder
//
//  Created by leo on 2018/12/29.
//  Copyright © 2018 ltebean. All rights reserved.
//

import UIKit
import AVFoundation
import Async
import MediaPlayer
import AVKit

class RecorderViewController: UIViewController {
    
    enum State {
        case ready
        case recording
    }
    
    let encodingQueue: DispatchQueue = DispatchQueue(label: "encoding queue", attributes: [])

    @IBOutlet weak var shootButton: UIButton!
    @IBOutlet weak var drawButton: UIButton!
    @IBOutlet weak var writeButton: UIButton!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var drawingCanvas: DrawingCanvas!
    
    let captureSession = CaptureSession()
    let processor = VideoProcessor()
    let videoWriter = VideoWriter()
    
    var state = State.ready

    override func viewDidLoad() {
    
        super.viewDidLoad()
        drawingCanvas.mode = .none
        
        captureSession.onVideoBuffer = { [weak self] buffer in
            self?.onVideoBuffer(sampleBuffer: buffer)
        }
        captureSession.onAudioBuffer = { [weak self] buffer in
            self?.onAudioBuffer(sampleBuffer: buffer)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        captureSession.requestAccess(completion: { granted in
            if granted {
                self.captureSession.setup()
                self.captureSession.startRunning()
                Async.main {
                    self.drawingCanvas.clearDraw()
                    self.drawingCanvas.clearText()
                }
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
    
    func setState(_ state: State) {
        self.state = state
    }
    
    func onVideoBuffer(sampleBuffer: CMSampleBuffer) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let time = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
        // render to screen
        var cameraImage = CIImage(cvPixelBuffer: pixelBuffer)
        cameraImage = processor.processWithFilter(image: cameraImage)
        let previewImage = processor.ciContext.createCGImage(cameraImage, from: cameraImage.extent)
        Async.main {
            self.previewView.layer.contents = previewImage
        }
        // writing to file
        if state == .recording {
            var frame: CIImage = cameraImage
            if let buffer = self.drawingCanvas.getTextBuffer() {
                frame = self.processor.process(image: frame, withOverlay: buffer)
            }
            if let buffer = self.drawingCanvas.getDrawingBuffer() {
                frame = self.processor.process(image: frame, withOverlay: buffer)
            }
            self.processor.ciContext.render(frame, to: pixelBuffer)
            Async.main {
                self.videoWriter.appendPixelBuffer(pixelBuffer: pixelBuffer, time: time)
            }
        }
    }
    
    func onAudioBuffer(sampleBuffer: CMSampleBuffer) {
        if state == .recording {
            Async.main {
                self.videoWriter.appendAudioBuffer(sampleBuffer)
            }
        }
    }
    
    func startRecording() {
        guard state == .ready else { return }
        setState(.recording)
        let url = URL(fileURLWithPath: File.shared.absolutePath("test.mp4"))
        File.shared.removeFileAtURL(url)
        videoWriter.startWriting(url)
    }
    
    func stopRecording() {
        guard state == .recording else { return }
        setState(.ready)
        videoWriter.stopWriting { url in
            Async.main {
                self.playVideo(url: url)
            }
        }
    }
    
    func playVideo(url: URL) {
        let player = AVPlayer(url: url)
        let vc = AVPlayerViewController()
        vc.videoGravity = AVLayerVideoGravity.resizeAspectFill
        vc.player = player
        present(vc, animated: true) {
            vc.player?.play()
        }
    }

    
}

extension RecorderViewController {
    
    @IBAction func filterButtonPressed(_ sender: Any) {
        processor.useNextFilter()
    }
    
    @IBAction func writeButtonPressed(_ sender: Any) {
        if (drawingCanvas.mode == .text) {
            drawingCanvas.mode = .none
        } else {
            drawingCanvas.mode = .text
        }
    }
    
    @IBAction func drawButtonPressed(_ sender: Any) {
        if (drawingCanvas.mode == .draw) {
            drawingCanvas.mode = .none
        } else {
            drawingCanvas.mode = .draw
        }
    }
    
    @IBAction func shootButtonPressed(_ sender: Any) {
        if (state == .ready) {
            shootButton.setTitle("STOP", for: .normal)
            startRecording()
        } else {
            shootButton.setTitle("START", for: .normal)
            stopRecording()
        }
    }
}
