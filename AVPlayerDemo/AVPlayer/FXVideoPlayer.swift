//
//  FXVideoPlayer.swift
//  AVPlayerDemo
//
//  Created by Dong on 2019/5/13.
//  Copyright © 2019 dong. All rights reserved.
//

import UIKit
import AVFoundation

public class FXVideoPlayer: NSObject , FXPlayerVideoPlayback {
    
    private var videoPlayer: AVPlayer?
    private var videoPlayerLayer: AVPlayerLayer?
    
    public var isReadyToPlay: Bool {
        return videoPlayer?.status == .readyToPlay
    }
    
    public var isAutoPlay: Bool = true
    
    private var _isPlaying = false
    public var isPlaying: Bool {
        return _isPlaying
    }
    
    public var currentTime: Double {
        return videoPlayer?.currentItem?.currentTime().seconds ?? 0
    }
    
    public var totalTime: Double {
        return videoPlayer?.currentItem?.duration.seconds ?? 0
    }
    
    private let _view = FXPlayerView()
    public var view: UIView {
        return _view
    }

    public override init() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(true)
            try session.setCategory(.playback)
        } catch {
            print(error)
        }
    }
    
    public func set(videoUrl: String) {
        guard let url = URL(string: videoUrl) else { return }
        let item = AVPlayerItem(url: url)
        item.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        item.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        videoPlayer = AVPlayer(playerItem: item)
        videoPlayerLayer = AVPlayerLayer(player: videoPlayer)
        videoPlayerLayer?.videoGravity = .resizeAspect
        _view.videoPlayerLayer = videoPlayerLayer
        
        videoPlayer?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main, using: {[weak self] (cmTime) in
            if let item = self?.videoPlayer?.currentItem {
                let currentTime = item.currentTime().seconds.isNaN ? 0 : item.currentTime().seconds
                let totalTime = item.duration.seconds.isNaN ? 0 : item.duration.seconds
                self?.setVideo(currentTime: currentTime, totalTime: totalTime)
            }
        })
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "status", let playerItem = object as? AVPlayerItem {
            switch playerItem.status {
            case .readyToPlay:
                if videoPlayer != nil {
                    if isAutoPlay {
                        videoPlayer?.play()
                    }else {
                        let totalTime = playerItem.duration.seconds.isNaN ? 0 : playerItem.duration.seconds
                        self.setVideo(currentTime: 0, totalTime: totalTime)
                    }
                }
            case .failed:
                break
            default:
                break
            }
        }
        
        if keyPath == "loadedTimeRanges", let playerItem = object as? AVPlayerItem {
            if let timeRange = playerItem.loadedTimeRanges.first as? CMTimeRange {
                let bufferTime = timeRange.start.seconds + timeRange.duration.seconds
                print(bufferTime)
            }
        }
    }
    
    public func play() {
        if videoPlayer == nil { return }
        if !isReadyToPlay { return }
        
        videoPlayer?.play()
    }
    
    public func pause() {
        videoPlayer?.pause()
    }
    
    
    // MARK: - private
    private func setVideo(currentTime: Double, totalTime: Double) {
        print("\(currentTime)--\(totalTime)")
    }
}


class FXPlayerView: UIView {
    
    var videoPlayerLayer: AVPlayerLayer? {
        didSet {
            if videoPlayerLayer != nil {
                self.layer.addSublayer(videoPlayerLayer!)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        videoPlayerLayer?.frame = self.bounds
    }
    
}
