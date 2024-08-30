//
//  ContentView.swift
//  VideoTrimSample
//
//  Created by Berkay Özdemir on 29.08.2024.
//

import SwiftUI
import AVKit


struct ContentView: View {
    
    @State var videoUrl:URL?
    @State var trimmedVideo:URL?
    @State var isVideoSelected:Bool = false
    @State var openVideoSelection:Bool = false
    
    var body: some View {
        VStack {
            if let videoUrl = videoUrl{
                HStack{
                    Spacer()
                    Button(action: {
                        self.videoUrl = nil
                    }, label: {
                        Image(systemName:"xmark.circle.fill").resizable().frame(width:18,height:18).foregroundColor(.red)
                    })
                }
                Spacer()
                VideoView(videoURL: videoUrl,trimmedVideo: $trimmedVideo)
                    .onAppear{
                        trimmedVideo = nil
                    }
                Spacer()
            } else {
                if let trimmedVideo = self.trimmedVideo{
                    let player = AVPlayer(url: trimmedVideo)
                    Text("Trimmed video:")
                    VideoPlayer(player: player)
                    
                }
                Button(action: {
                    openVideoSelection = true
                }, label: {
                    Image(systemName: "chevron.right")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text("Select Video")
                })
                .sheet(isPresented: $openVideoSelection, content: {
                    VideoPicker(videoURL: $videoUrl)
                })
            }

        }
        .padding()
    }
}

#Preview {
    ContentView()
}
