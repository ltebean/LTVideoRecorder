//
//  AVCaptureDevice.swift
//  Slowmo
//
//  Created by ltebean on 16/4/16.
//  Copyright © 2016年 io.ltebean. All rights reserved.
//

import Foundation
import UIKit

open class File: NSObject {
    
    public static let shared = File()
    
    let fileManager = Foundation.FileManager.default
    let documentPath = try! Foundation.FileManager.default.url(for: Foundation.FileManager.SearchPathDirectory.documentDirectory, in: Foundation.FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: true).path
    
    open func absolutePath(_ path: String) -> String {
        return documentPath + "/" + path
    }
    
    open func fileExistsAtRelativePath(_ path: String) -> Bool {
        return fileManager.fileExists(atPath: absolutePath(path))
    }
    
    open func fileExistsAtPath(_ path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }
    
    open func createDir(atPath path: String) -> Bool {
        do {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return false
        }
        return true
    }
    
    
    open func removeFileAtPath(_ path: String) {
        do {
            try fileManager.removeItem(atPath: path)
        } catch {
            return
        }
    }
    
    open func removeFileAtURL(_ url: URL?) {
        guard let url = url else { return }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            return
        }
    }
    
    
    
    open func clearDocDir() {
        do {
            let files = try fileManager.contentsOfDirectory(atPath: documentPath)
            for file in files {
                removeFileAtPath(absolutePath(file))
            }
        } catch {
            return
        }
    }
}
