//
//  Canvas.swift
//  GhostFace
//
//  Created by leo on 16/12/11.
//  Copyright © 2016年 CaowuTechnology. All rights reserved.
//

import UIKit

@IBDesignable
class DrawingCanvas : XibBasedView {
    
    var drawColor: UIColor = UIColor.white
    var drawWidth: CGFloat = 8.0
    var lastPoint: CGPoint = CGPoint.zero
    var drawingbuffer: UIImage?
    var textbuffer: UIImage?
    

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var pallet: Pallet!
    
    enum Mode {
        case draw
        case text
        case none
    }
    
    var onKeyboardDismiss: (() -> ())?
    
    var mode = Mode.none {
        didSet {
            if mode == .draw {
                pallet.isHidden = false
                textView.isUserInteractionEnabled = false
                textView.resignFirstResponder()
            } else if (mode == .text) {
                pallet.isHidden = false
                textView.isUserInteractionEnabled = true
                textView.becomeFirstResponder()
            } else {
                pallet.isHidden = true
                textView.isUserInteractionEnabled = false
                textView.resignFirstResponder()
                if (oldValue == .draw) {
                    clearDraw()
                }
            }
        }
    }
    
    override func load() {
        super.load()
        textView.delegate = self
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(DrawingCanvas.handlePan(_:)))
        addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(DrawingCanvas.handleTap(_:)))
         addGestureRecognizer(tap)

        
        pallet.onColorSelected = { [weak self] color in
            guard let this = self else {
                return
            }
            this.drawColor = color
            if this.mode == .text {
                this.textView.textColor = color
//                this.textAttrs.foregroundColor(color)
//                this.textView.typingAttributes = this.textAttrs.dictionary
//                this.textView.attributedText = NSAttributedString(string: this.textView.text, attributes: this.textAttrs.dictionary)
                this.drawTextToBuffer()
                
            }
        }

//        textView.typingAttributes = textAttrs.dictionary
    }
    
    
    func clearDraw() {
        drawingbuffer = nil
        layer.contents = nil
    }
    
    func clearText() {
        textbuffer = nil
        textView.text = ""
    }
    
    func getDrawingBuffer() -> UIImage? {
        return drawingbuffer
    }
    func getTextBuffer() -> UIImage? {
        return textbuffer
    }
    
    
    private func drawLine(a: CGPoint, b: CGPoint, buffer: UIImage?) -> UIImage {
        let size = bounds.size
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        if let buffer = drawingbuffer {
            buffer.draw(in: bounds)
        }
        
        drawColor.setStroke()
        context.setLineWidth(drawWidth)
        context.setLineCap(.round)
        context.move(to: a)
        context.addLine(to: b)
        context.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, mode == .text else {
            return
        }
        mode = .none
        onKeyboardDismiss?()
        textView.resignFirstResponder()
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard mode == .draw else {
            return
        }
        let point = gesture.location(in: self)
        switch gesture.state {
        case .began:
            startAtPoint(point: point)
        case .changed:
            continueAtPoint(point: point)
        case .ended:
            endAtPoint(point: point)
        case .failed:
            endAtPoint(point: point)
        default:
            break
        }
        layer.contents = drawingbuffer?.cgImage
    }
    
    
    private func startAtPoint(point: CGPoint) {
        lastPoint = point
    }
    
    private func continueAtPoint(point: CGPoint) {
        drawingbuffer = drawLine(a: lastPoint, b: point, buffer: drawingbuffer)
        lastPoint = point
    }
    
    private func endAtPoint(point: CGPoint) {
        lastPoint = CGPoint.zero
    }
    
    func drawTextToBuffer() {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
//        let text = textView.text as NSString
//        text.draw(in: textView.frame, withAttributes: textAttrs.dictionary)
        textView.drawHierarchy(in: textView.frame, afterScreenUpdates: true)
        textbuffer = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
}


extension DrawingCanvas: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
       drawTextToBuffer()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            mode = .none
            onKeyboardDismiss?()
            return false
        }
        return true
    }

}
