//
//  FXAudioPlayer.swift
//  AVPlayerDemo
//
//  Created by Dong on 2019/5/8.
//  Copyright © 2019 dong. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

@objc public protocol FXAudioPlayerDelegate {
    func audioPlayer(_ player: FXAudioPlayer, currentTime: Double, totalTime: Double)
}

public class FXAudioPlayer: NSObject  {
    
    public enum PlayStatus {
        case playing
        case paused
        case stoped
        case loading
    }
    
    private var audioPlayer: AVPlayer?
    private var audioUrls = [URL]()
    private var currentIndex: Int = 0

    public var status = PlayStatus.paused {
        didSet {
            playStatus?(status)
        }
    }
    
    public var isPlaying = false {
        didSet{
            status = isPlaying ? .playing : .paused
        }
    }
    
    public var isLoading = false {
        didSet {
            if isLoading {
                status = .loading
            }else {
                status = isPlaying ? .playing : .paused
            }
        }
    }
    
    public var playStatus: ((_ status: PlayStatus) -> Void)?
    
    public var isStartSeek = false
    
    public weak var delegate: FXAudioPlayerDelegate?
    
    public override init() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(true)
            try session.setCategory(.playback)
        } catch {
            print(error)
        }
    }
    
    private func setAudioPlayer() {
        if audioUrls.isEmpty { return }
        
        let item = AVPlayerItem(url: audioUrls[currentIndex])
        item.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        audioPlayer = AVPlayer(playerItem: item)
        
        audioPlayer?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: DispatchQueue.main, using: {[weak self] (cmTime) in
            
            if let item = self?.audioPlayer?.currentItem {
                let currentTime = item.currentTime().seconds.isNaN ? 0 : item.currentTime().seconds
                let totalTime = item.duration.seconds.isNaN ? 0 : item.duration.seconds
                self?.setAudio(currentTime: currentTime, totalTime: totalTime)
            }
        })
        
        setRemoteControl()
    }
    
    private func setRemoteControl() {
        
//        UIApplication.shared.beginReceivingRemoteControlEvents()

        MPRemoteCommandCenter.shared().playCommand.addTarget {[weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.play()
            return .success
        }

        MPRemoteCommandCenter.shared().pauseCommand.addTarget {[weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.pause()
            return .success
        }
        
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget {[weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.playNext()
            return .success
        }
        
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget {[weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.playPrevious()
            return .success
        }
        
    }
    
    /// 更换 playeritem
    private func replacePlayerItem() {
        audioPlayer?.currentItem?.removeObserver(self, forKeyPath: "status")
        audioPlayer?.currentItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        audioPlayer?.currentItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        let item = AVPlayerItem(url: audioUrls[currentIndex])
        item.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        audioPlayer?.replaceCurrentItem(with: item)
    }
    
    /// 准备下一个
    private func prepareNext() {
        if audioPlayer == nil { return }
        if currentIndex <= 1 { return }
        if currentIndex >= audioUrls.count - 1 {
            currentIndex = 0
        }else {
            currentIndex += 1
        }
        
        replacePlayerItem()
    }
    
    private func setAudio(currentTime: Double, totalTime: Double) {
        if currentTime == totalTime {
            if currentIndex == audioUrls.count - 1 {
                isPlaying = false
                status = .stoped
            }else {
                prepareNext()
                isPlaying = true
            }
        }
        self.delegate?.audioPlayer(self, currentTime: currentTime, totalTime: totalTime)
        
        setLockScreenPlayingInfo(with: currentTime, totalTime: totalTime)
    }
    
    private func setLockScreenPlayingInfo(with currentTime: Double, totalTime: Double) {
        
        var infoDict = [String : Any]()
        infoDict[MPMediaItemPropertyTitle] = "\(currentIndex)"
        infoDict[MPMediaItemPropertyPlaybackDuration] = totalTime
        infoDict[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        infoDict[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = infoDict
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let playerItem = object as? AVPlayerItem else { return }
        
        if keyPath == "status"{
            switch playerItem.status {
            case .readyToPlay:
                if audioPlayer != nil {
                    if isPlaying {
                        audioPlayer?.play()
                    }else {
                        let totalTime = playerItem.duration.seconds.isNaN ? 0 : playerItem.duration.seconds
                        self.setAudio(currentTime: 0, totalTime: totalTime)
                    }
                }
            case .failed:
                prepareNext()
            default:
                break
            }
        }
        
        else if keyPath == "playbackBufferEmpty" {
            if playerItem.isPlaybackBufferEmpty {
                self.isLoading = true
            }
        }
        
        else if keyPath == "playbackLikelyToKeepUp" {
            print("playbackLikelyToKeepUp")
            if playerItem.isPlaybackLikelyToKeepUp {
                self.isLoading = false
            }
        }
    }
    
    /// 设置播放URL
    /// - Parameter audioUrls: url数组
    public func set(audioUrls: [URL]) {
        if audioUrls.isEmpty { return }
        self.audioUrls = audioUrls
        if audioPlayer == nil {
            setAudioPlayer()
        }else {
            currentIndex = 0
            replacePlayerItem()
        }
    }
    
    /// 播放
    @objc public func play() {
        if audioUrls.count <= 0 { return }
//        if audioPlayer?.status != .readyToPlay { return }
        if audioPlayer == nil {
            setAudioPlayer()
        }else {
            if status == .stoped {
                replacePlayerItem()
            }
            audioPlayer?.play()
        }
        isPlaying = true
    }
    
    /// 暂停
    @objc public func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }
    
    /// 播放下一个
    @objc public func playNext() {
        if audioPlayer == nil { return }
        if audioUrls.count <= 1 { return }
        
        if currentIndex >= audioUrls.count - 1 {
            currentIndex = 0
        }else {
            currentIndex += 1
        }
        
        replacePlayerItem()
        isPlaying = true
    }
    
    /// 播放上一个
    @objc public func playPrevious() {
        if audioPlayer == nil { return }
        if audioUrls.count <= 1 { return }
        
        if currentIndex <= 0 {
            currentIndex = audioUrls.count - 1
        }else {
            currentIndex -= 1
        }
        
        replacePlayerItem()
        isPlaying = true
    }
    
    public func seek(to seconds: Double, completionHandler: ((Bool) -> Void)? = nil ) {
        audioPlayer?.seek(to: CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), completionHandler: { (isFinished) in
            completionHandler?(isFinished)
        })
    }
    
    deinit {
        audioPlayer?.currentItem?.removeObserver(self, forKeyPath: "status")
        audioPlayer?.currentItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        audioPlayer?.currentItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        pause()
        audioPlayer?.removeTimeObserver(self)
        audioPlayer = nil
        
        UIApplication.shared.endReceivingRemoteControlEvents()
    }
}


public extension Double {
    
    func formatToTime() -> String {
        var timeString = "00:00"
        if self < 60 {
            timeString = String(format: "00:%02d", Int(self < 0 ? 0 : self))
        }else {
            var minute = self / 60
            let seconds = self.truncatingRemainder(dividingBy: 60)
            if minute < 60 {
                timeString = String(format: "%02d:%02d", Int(minute), Int(seconds))
            }else {
                let hour = minute / 60
                minute = minute.truncatingRemainder(dividingBy: 60)
                timeString = String(format: "%02d:%02d:%02d", Int(hour), Int(minute), Int(seconds))
            }
        }
        return timeString
    }
}
