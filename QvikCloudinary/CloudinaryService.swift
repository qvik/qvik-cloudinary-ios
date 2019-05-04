// The MIT License (MIT)
//
// Copyright (c) 2015-2016 Qvik (www.qvik.fi)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import Cloudinary

import QvikSwift

/// Notification that is sent whenever all pending operations have completed. 
public let QCSAllOperationsCompleted = "QCSAllOperationsCompleted"

/**
 Provides functionality for uploading media data to a cloud storage on Cloudinary CDN.
 */
open class CloudinaryService {
    /// Upload response datatype
    public typealias UploadResponse = (success: Bool, url: String?, width: Int?, height: Int?)
    
    /// Cloudinary API facade
    fileprivate var cloudinary: CLCloudinary?
    
    /// Number of all current operations.
    fileprivate var ongoingOperationsCount = 0
    
    /// Lock for synchronizing access to ```ongoingOperationsCount```
    fileprivate let ongoingOperationsCountLock = ReadWriteLock()
    
    // MARK: Private methods
    
    fileprivate func operationStarted() {
        ongoingOperationsCountLock.withWriteLock {
            self.ongoingOperationsCount += 1
        }
    }
    
    fileprivate func operationCompleted() -> Bool {
        return ongoingOperationsCountLock.withWriteLock {
            self.ongoingOperationsCount -= 1
            
            return (self.ongoingOperationsCount == 0)
        }
    }
    
    /// Return Cloudinary public id for the image. Cloudinary public id is the identifier
    /// before file ending
    fileprivate func getPublicId(_ url: String) -> String {
        let urlWithoutFileFormat = url.split(".jpg")[0]
        let urlParts = urlWithoutFileFormat.split("/")
        let publicId = urlParts[urlParts.count - 1]
        
        return publicId
    }
    
    // MARK: Public methods
    
    /**
     Uploads an image as a JPEG.
     
     This method performs JPEG encoding and can be a heavy operation; consider calling this method
     call in a background thread and optionally wrapping it in ```autoreleasepool { .. }```.
     */
    open func upload(image: UIImage, progressCallback: @escaping ((Float) -> Void), completionCallback: @escaping ((UploadResponse) -> Void)) {
        if let imageData = image.jpegData(compressionQuality: 0.9) {
            upload(imageData: imageData, progressCallback: progressCallback, completionCallback: completionCallback)
        }
    }
    
    /// Uploads image from image data.
    open func upload(imageData: Data, progressCallback: @escaping ((Float) -> Void), completionCallback: @escaping ((UploadResponse) -> Void)) {
        log.verbose("Starting Cloudinary image upload..")
        
        // TODO should we do uploader per upload?
        let uploader = CLUploader(cloudinary, delegate: nil)
        let options = ["tags": "ios_upload"]
        
        operationStarted()
        
        uploader?.upload(imageData, options: options, withCompletion: { (successResult, errorResult, code, context) -> Void in
            log.debug("Image upload completed, successResult: \(String(describing: successResult)), errorResult: \(String(describing: errorResult)), code: \(code)")
            if let url = successResult?["url"] as? String,
                let width = successResult?["width"] as? Int,
                let height = successResult?["height"] as? Int {
                    completionCallback((success: true, url: url, width: width, height: height))
            } else {
                let allCompleted = self.operationCompleted()
                completionCallback((success: false, url: nil, width: nil, height: nil))
                if allCompleted {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: QCSAllOperationsCompleted), object: self)
                }
            }
            }, andProgress: { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite, context) -> Void in
                log.verbose("Upload progress: \(totalBytesWritten) / \(totalBytesExpectedToWrite)")
                progressCallback(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))
        })
        
    }
    
    /**
     Uploads a video to the cloud storage.
     
     - parameter videoFileUrl: readable local video url; this should be a path to an exported video;
     see ```exportVideoDataForAssetUrl()```.
     - returns: true if the download started ok, false if there were errors
     */
    open func uploadVideo(videoFilePath: String, progressCallback: @escaping ((Float) -> Void), completionCallback: @escaping ((UploadResponse) -> Void)) -> Bool {
        assert(Thread.isMainThread, "Must be called on the main thread")
        
        log.verbose("Starting Cloudinary video upload - video file path: \(videoFilePath)")
        let uploader = CLUploader(cloudinary, delegate: nil)
        
        let options = [
            "tags": "ios_upload",
            "resource_type": "video",
            "format": "mp4"
        ]
        
        operationStarted()
        
        log.verbose("Starting Cloudinary uploader..")
        uploader?.upload((videoFilePath as NSString), options: options, withCompletion: { (successResult, errorResult, code, context) in
            log.debug("Video upload completed, successResult: \(String(describing: successResult)), errorResult: \(String(describing: errorResult)), code: \(code)")
            let allCompleted = self.operationCompleted()
            
            if let url = successResult?["url"] as? String,
                let width = successResult?["width"] as? Int,
                let height = successResult?["height"] as? Int {
                    completionCallback((success: true, url: url, width: width, height: height))
            } else {
                completionCallback((success: false, url: nil, width: nil, height: nil))
            }
            
            if allCompleted {
                NotificationCenter.default.post(name: Notification.Name(rawValue: QCSAllOperationsCompleted), object: self)
            }
            }, andProgress: { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite, context) -> Void in
                log.verbose("Upload progress: \(totalBytesWritten) / \(totalBytesExpectedToWrite)")
                progressCallback(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))
        })
        
        return true
    }
    
    /// Remove Image or Video asset from Cloudinary based on its url
    open func removeAsset(_ url: String) {
        // Obtain asset public id from url
        let publicId = getPublicId(url)
        
        let uploader = CLUploader(cloudinary, delegate: nil)
        
        // Destroy asset from Cloudinary and all it's derivatives
        uploader?.destroy(publicId, options: nil)
    }
    
    // MARK: Lifecycle etc
    
    public init(configUrl: String) {
        cloudinary = CLCloudinary(url: configUrl)
    }
}
