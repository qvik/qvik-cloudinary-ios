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

import UIKit
import AVKit
import AVFoundation

import QvikSwift

public let QCUtilsErrorDomain = "QvikCloudinaryUtilsErrorDomain"
public let QCUtilsVideoEncodeFailed = -100
public let QCUtilsCouldNotGetExportSession = -101
public let QCUtilsCouldNotGetAssetURL = -102

/**
 Asynchronously get downsampled video data from an AVAssetExportSession.
 The caller should delete the file at videoFileUrl once it is no longer needed.
 The callback will be called on the main thread.
 */
private func exportVideoDataForExportSession(exportSession: AVAssetExportSession, completionCallback: ((videoFileUrl: NSURL?, error: NSError?) -> Void)) {
    let startTime = NSDate()
    
    // Allocate a temporary file to write to
    let tempFilePath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(NSUUID().UUIDString)
    
    // Configure the export session
    exportSession.canPerformMultiplePassesOverSourceMediaData = true
    exportSession.outputFileType = AVFileTypeMPEG4
    exportSession.outputURL = NSURL(fileURLWithPath: tempFilePath)
    
    exportSession.exportAsynchronouslyWithCompletionHandler() {
        log.debug("Video export completed, status: \(exportSession.status), error: \(exportSession.error)")
        
        if exportSession.status == .Completed {
            log.verbose("Video encoding OK, the process took \(-startTime.timeIntervalSinceNow) seconds")
            log.verbose("Video written to URL: \(exportSession.outputURL)")
            
            runOnMainThread {
                // Callback on main thread
                completionCallback(videoFileUrl: exportSession.outputURL, error: nil)
            }
        } else {
            runOnMainThread {
                // Callback on main thread
                if let error = exportSession.error {
                    completionCallback(videoFileUrl: nil, error: error)
                } else {
                    completionCallback(videoFileUrl: nil, error: NSError(domain: QCUtilsErrorDomain, code: QCUtilsVideoEncodeFailed, userInfo: nil))
                }
            }
        }
    }
}

/**
 Asynchronously get downsampled video data for a AVAsset url.
 The caller should delete the file at videoFileUrl once it is no longer needed.
 The ```completionCallback``` will be called on the main thread.
 
 - parameter url: Video asset url (eg. UIImagePickerControllerMediaURL etc.)
 - parameter presetName: video preset used for exporting. See ```AVAssetExportPreset*``` constants.
 Uses ```AVAssetExportPreset1280x720``` by default.
 - parameter completionCallback: called when export operation completes; ```videoFileUrl``` points to the created video file on disk; the caller should delete this file once it is no longer needed. ```error``` is set to a NSError in case of errors in operation.
 */
public func exportVideoDataForAssetUrl(url: NSURL, presetName: String = AVAssetExportPreset1280x720, completionCallback: ((videoFileUrl: NSURL?, error: NSError?) -> Void)) {
    let asset = AVAsset(URL: url)
    guard let exportSession = AVAssetExportSession(asset: asset, presetName: presetName) else {
        completionCallback(videoFileUrl: nil, error: NSError(domain: QCUtilsErrorDomain, code: QCUtilsCouldNotGetExportSession, userInfo: nil))
        return
    }
    
    exportVideoDataForExportSession(exportSession, completionCallback: completionCallback)
}

/**
 Calculates the required downscale ratio for an image in a way that the
 image returned from Cloudinary is not larger than the given max image size.
 
 If the max size is not defined or the image is already smaller, the original url is returned, 
 with EXIF path injected to respect orientation.
 */
func scaledCloudinaryUrl(width width: CGFloat, height: CGFloat, url: String, maxSize: CGSize) -> String {
    if (width < maxSize.width) && (height < maxSize.height) {
        // Image wont be scaled; include exif info to retain orientation
        let rotatedUrl = url.stringByReplacingOccurrencesOfString("/upload/", withString: "/upload/a_exif/")
        return rotatedUrl
    }
    
    let widthRatio = width / maxSize.width
    let heightRatio = height / maxSize.height
    let scale = 1.0 / max(widthRatio, heightRatio)
    let scaleFormat = "w_\(scale)"
    let scaledUrl = url.stringByReplacingOccurrencesOfString("/upload/", withString: "/upload/\(scaleFormat)/")
    
    return scaledUrl
}