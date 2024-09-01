//
//  VideoView.swift
//  VideoTrimSample
//
//  Created by Berkay Özdemir on 1.09.2024.
//

import SwiftUI
import AVKit
import UIKit



struct VideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}


struct VideoView: View {
    let videoURL: URL
    
    let width = UIScreen.main.bounds.width
    
    @Binding var trimmedVideo: URL?
    var action:((Bool) -> Void)?
    
    
    @State var trimStart: Double?
    @State var trimEnd: Double?
    
    @State private var player: AVPlayer
    @State private var thumbnails: [UIImage] = []
    @State private var sliderProgress: CGFloat = 0.0
    @State private var startTrim: CGFloat = 0.0
    @State private var endTrim: CGFloat = 1.0
    @State private var videoDuration: Double?
    
    @State var showProgress:Bool = false
    
    @State private var isPlaying: Bool = false
    
    @State var leftMoving:Bool = false
    @State var rightMoving:Bool = false
    
    init(videoURL: URL, trimmedVideo: Binding<URL?>,trimmedCompletion:@escaping (Bool)->Void) {
        self.action = trimmedCompletion
        self.videoURL = videoURL
        self._player = State(initialValue: AVPlayer(url: videoURL))
        self._trimmedVideo = trimmedVideo
    }
    
    func trimVideo(completion: @escaping (Bool) -> Void) {
        
        /*guard let start = trimStart, let end = trimEnd else {
            completion(false)
            return }*/
        
        //trimStart = Double(startTrim) * (videoDuration ?? 1.0)
        if videoDuration == nil{
            videoDuration = player.currentItem?.asset.duration.seconds
        }
        
        if trimStart == nil{
            trimStart = Double(startTrim) * (videoDuration ?? 1.0)
        }
        
        if trimEnd == nil{
            trimEnd = Double(endTrim) * (videoDuration ?? 1.0)
        }
        
        let start = trimStart ?? 0
        let end = trimEnd ?? videoDuration!
        
        self.showProgress = true
        
        let asset = AVAsset(url: videoURL)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        
        let trimmedOutputURL = FileManager.default.temporaryDirectory.appendingPathComponent("trimmedVideo.mov")
        
        if FileManager.default.fileExists(atPath: trimmedOutputURL.path) {
            try? FileManager.default.removeItem(at: trimmedOutputURL)
        }
        
        exportSession?.outputURL = trimmedOutputURL
        exportSession?.outputFileType = .mov
        
        let startTime = CMTime(seconds: start, preferredTimescale: 600)
        let endTime = CMTime(seconds: end, preferredTimescale: 600)
        exportSession?.timeRange = CMTimeRange(start: startTime, end: endTime)
        
        exportSession?.exportAsynchronously {
            switch exportSession?.status {
            case .completed:
                DispatchQueue.main.async {
                    self.trimmedVideo = trimmedOutputURL
                    self.showProgress = false
                    completion(true)
                }
            case .failed, .cancelled:
                self.showProgress = false
                completion(false)
                print("Failed to export video: \(exportSession?.error?.localizedDescription ?? "Unknown error")")
            default:
                self.showProgress = false
                completion(false)
                break
            }
        }
    }
    
    var progressView: some View{
        ProgressView("")
            .progressViewStyle(.circular)
            .tint(.white)
            .scaleEffect(2)
            .padding(30)
    }
    
    var body: some View {
        VStack {
            ZStack {
                VideoPlayerView(player: player)
                    .frame(height: 300)
                    .onAppear {
                        generateThumbnails(from: videoURL)
                        observePlayerProgress()
                        videoDuration = player.currentItem?.asset.duration.seconds
                        self.trimmedVideo = nil
                    }
                    .overlay(
                        ZStack {
                            if !isPlaying {
                                Color.black.opacity(0.3)
                                Image(systemName: "play.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.white)
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .onTapGesture {
                        let currentTime = player.currentTime().seconds
                        let duration = videoDuration ?? 0

                        if isPlaying {
                            player.pause()
                        } else {
                            
                            if let trimEnd = trimEnd{
                                if currentTime >= trimEnd {
                                    if let start = trimStart{
                                        player.seek(to: CMTime(seconds: start, preferredTimescale: 600))
                                    } else{
                                        player.seek(to: .zero)
                                    }
                                    
                                }
                            } else {
                                if currentTime >= duration {
                                    if let start = trimStart{
                                        player.seek(to: CMTime(seconds: start, preferredTimescale: 600))
                                    } else{
                                        player.seek(to: .zero)
                                    }
                                    
                                }
                            }
                            
                            player.play()
                        }
                        isPlaying.toggle()
                    }
                
                /*if let trimmedVideo = trimmedVideo {
                    Text("Trimmed video saved at: \(trimmedVideo.path)")
                }*/
                
                if showProgress{
                    progressView
                }
            }
            
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    ForEach(thumbnails, id: \.self) { thumbnail in
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 60)
                    }
                }
                .frame(width: width)
                .clipped()
                
                Rectangle()
                    .fill(Color.red.opacity(0))
                    .frame(width: 2, height: 60)
                    .offset(x: sliderProgress * UIScreen.main.bounds.width)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newProgress = value.location.x / UIScreen.main.bounds.width
                                sliderProgress = max(0, min(newProgress, 1))
                                let newTime = Double(sliderProgress) * (videoDuration ?? 1.0)
                                player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
                            }
                    )
                
                Group {
                    Rectangle()
                        .fill(Color.orange) //255,203,1
                        .frame(width: leftMoving ? 20 : 10)
                        .overlay(
                            VStack{
                                if leftMoving{
                                    Image(systemName:"chevron.right").resizable().scaledToFit().frame(width:10).foregroundStyle(.black)
                                }
                            }
                        )
                        .offset(x: startTrim * UIScreen.main.bounds.width)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.linear(duration: 0.5)){
                                        leftMoving = true
                                    }
                                    startTrim = max(0, min(value.location.x / UIScreen.main.bounds.width, endTrim))
                                    trimStart = Double(startTrim) * (videoDuration ?? 1.0)
                                }
                                .onEnded { value in
                                    withAnimation(.linear(duration: 0.5)){
                                        leftMoving = false
                                    }
                                    if let start = trimStart {
                                        player.seek(to: CMTime(seconds: start, preferredTimescale: 600))
                                    }
                                }
                        )
                    
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: rightMoving ? 20 : 10)
                        .overlay(
                            VStack{
                                if rightMoving{
                                    Image(systemName:"chevron.left").resizable().scaledToFit().frame(width:10).foregroundStyle(.black)
                                }
                            }
                        )
                        .offset(x: (endTrim * UIScreen.main.bounds.width) - (rightMoving ? 20 : 10))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.linear(duration: 0.5)){
                                        rightMoving = true
                                    }
                                    endTrim = max(startTrim, min(value.location.x / UIScreen.main.bounds.width, 1))
                                    trimEnd = Double(endTrim) * (videoDuration ?? 1.0)
                                }
                                .onEnded { value in
                                    withAnimation(.linear(duration: 0.5)){
                                        rightMoving = false
                                    }
                                    if let start = trimStart {
                                        player.seek(to: CMTime(seconds: start, preferredTimescale: 600))
                                    }
                                }
                        )
                }
                
                Rectangle()
                    .fill(Color.black.opacity(0.65))
                    .frame(width: startTrim * UIScreen.main.bounds.width, height: 60)
                
                Rectangle()
                    .fill(Color.black.opacity(0.65))
                    .frame(width: (1 - endTrim) * UIScreen.main.bounds.width, height: 60)
                    .offset(x: endTrim * UIScreen.main.bounds.width)
            }
            .frame(height: 60)
            .frame(width: width)
            
            Button(action: {
                if !showProgress{
                    trimVideo { isDone in
                        
                        if let action = action{
                                action(isDone)
                        }
                    }
                }
                else{
                    print("video trimming in progress")
                }
            }) {
                Text("Trim Video")
            }
            .padding()
            /*.sheet(isPresented: $showTrimmed, content: {
                if let trimmedVideo = trimmedVideo {
                    //VideoView(videoURL: trimmedVideo)
                    Text("Add Your functionality based on your app.")
                }
            })*/
        }
    }
    
    private func generateThumbnails(from url: URL) {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero
        
        let times: [NSValue] = stride(from: 0, to: asset.duration.seconds, by: asset.duration.seconds / 10).map { time in
            return NSValue(time: CMTime(seconds: time, preferredTimescale: 600))
        }
        
        thumbnails = times.compactMap { time in
            if let cgImage = try? generator.copyCGImage(at: time.timeValue, actualTime: nil) {
                return UIImage(cgImage: cgImage)
            }
            return nil
        }
    }
    
    private func observePlayerProgress() {
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            let totalDuration = player.currentItem?.duration.seconds ?? 1
            sliderProgress = CGFloat(time.seconds / totalDuration)
            
            if let end = trimEnd, time.seconds >= end {
                player.pause()
                isPlaying = false
            }
        }
    }
}



struct VideoPicker: UIViewControllerRepresentable {
    @Binding var videoURL: URL?
    @Environment(\.presentationMode) private var presentationMode

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: VideoPicker

        init(parent: VideoPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let url = info[.mediaURL] as? URL {
                parent.videoURL = url
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.mediaTypes = ["public.movie"]
        picker.videoQuality = .typeHigh
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
