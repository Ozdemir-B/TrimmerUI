//
//  VideoEditorView.swift
//  VideoTrimSample
//
//  Created by Berkay Özdemir on 30.08.2024.
//

import SwiftUI
import AVFoundation

struct VideoSlider:View {
    
    @Binding var sliderLocation:Double
    
    var thumbnails:[UIImage]
    var duration:Double
    @State var start:Double?
    @State var end:Double?
    
    
    
    init(sliderLocation:Binding<Double>,thumbnails: [UIImage], duration: Double) {
        self.thumbnails = thumbnails
        self.duration = duration
        self.start = Double(0)
        self._end = State(wrappedValue: duration)
        self._sliderLocation = sliderLocation
    }
    
    func moveSlider(sliderLocation:Double){
        
    }
    
    var slider: some View{
        Color.white.frame(width:5,height:35).cornerRadius(10)
    }
    
    var body: some View {
        ZStack{
            HStack(spacing:0){
                ForEach(thumbnails,id:\.self){
                    image in
                    Image(uiImage: image).resizable().scaledToFill()
                }
            }.frame(height:30)
        }
    }
}


struct VideoEditorView: View {
    
    var originalVideo:AVAsset
    var videoOps:VideoOps
    @State var editedVideo:AVAsset?
    
    @State var sliderLocation:Double = 0
    
    init(videoUrl:URL?){
        self.originalVideo = AVURLAsset(url: videoUrl!)
        self.videoOps = VideoOps(videoURL: videoUrl!)
        
    }
    
    var body: some View {
        VStack{
            Color.primary.edgesIgnoringSafeArea(.horizontal).frame(height:120)
            
            VideoSlider(sliderLocation:$sliderLocation,thumbnails: videoOps.get_thumbnails(), duration: originalVideo.duration.seconds)
        }
    }
}


