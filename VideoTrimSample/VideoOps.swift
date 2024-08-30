//
//  VideoOps.swift
//  VideoTrimSample
//
//  Created by Berkay Özdemir on 30.08.2024.
//

import AVFoundation
import UIKit
import Photos

class VideoOps {
    private var videoURL: URL
    private var trimmedURL: URL?

    init(videoURL: URL) {
        self.videoURL = videoURL
    }
    
    // Function to get 10 thumbnails from the video
    func get_thumbnails(videoAsset:AVAsset? = nil) -> [UIImage] {
        var asset:AVAsset = AVAsset()
        if let videoAsset = videoAsset{
            asset = videoAsset
        } else{
            asset = AVAsset(url: videoURL)
        }
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 426, height: 240) // 240p resolution

        var thumbnails: [UIImage] = []
        let duration = asset.duration
        let interval = CMTimeMultiplyByFloat64(duration, multiplier: 0.1) // 10 equal intervals
        
        for i in 0..<10 {
            let time = CMTimeMultiply(interval, multiplier: Int32(i))
            if let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: nil) {
                thumbnails.append(UIImage(cgImage: cgImage))
            }
        }
        
        return thumbnails
    }
    
    // Function to trim the video
    func trim_video(start: Int, end: Int) -> AVAsset? {
        let asset = AVAsset(url: videoURL)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("trimmedVideo.mp4")
        self.trimmedURL = outputURL
        
        exportSession?.outputURL = outputURL
        exportSession?.outputFileType = .mp4
        
        let startTime = CMTime(seconds: Double(start), preferredTimescale: 600)
        let endTime = CMTime(seconds: Double(end), preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        exportSession?.timeRange = timeRange
        
        let semaphore = DispatchSemaphore(value: 0)
        
        exportSession?.exportAsynchronously {
            semaphore.signal()
        }
        
        semaphore.wait()
        
        if exportSession?.status == .completed {
            return AVAsset(url: outputURL)
        } else {
            return nil
        }
    }
    
    
    func trim_video_old(start: Int, end: Int) -> URL? {
        let asset = AVAsset(url: videoURL)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("trimmedVideo.mp4")
        self.trimmedURL = outputURL
        
        exportSession?.outputURL = outputURL
        exportSession?.outputFileType = .mp4
        
        let startTime = CMTime(seconds: Double(start), preferredTimescale: 600)
        let endTime = CMTime(seconds: Double(end), preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        exportSession?.timeRange = timeRange
        
        let semaphore = DispatchSemaphore(value: 0)
        
        exportSession?.exportAsynchronously {
            semaphore.signal()
        }
        
        semaphore.wait()
        
        return exportSession?.status == .completed ? outputURL : nil
    }
    
    // Function to save the trimmed video to the gallery
    func save_video(completion: @escaping (Bool) -> Void) {
        guard let trimmedURL = trimmedURL else {
            completion(false)
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: trimmedURL)
        }) { saved, error in
            DispatchQueue.main.async {
                completion(saved && error == nil)
            }
        }
    }
}
