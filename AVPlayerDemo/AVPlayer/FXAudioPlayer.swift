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
    
    private var audioPlayer: AVPlayer?
    private var audioUrls = [URL]()
    private var currentIndex: Int = 0

    public var isPlaying = false {
        didSet{
            playStatus?(isPlaying)
        }
    }
    public var playStatus: ((_ isPlaying: Bool) -> Void)?
    
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
        
        let item = AVPlayerItem(url: audioUrls[currentIndex])
        item.addObserver(self, forKeyPath: "status", options: .new, context: nil)
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
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        MPRemoteCommandCenter.shared().playCommand.addTarget(self, action: #selector(play))
        MPRemoteCommandCenter.shared().pauseCommand.addTarget(self, action: #selector(pause))
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget(self, action: #selector(playNext))
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget(self, action: #selector(playPrevious))
    }
    
    private func replacePlayerItem() {
        audioPlayer?.currentItem?.removeObserver(self, forKeyPath: "status")
        let item = AVPlayerItem(url: audioUrls[currentIndex])
        item.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        audioPlayer?.replaceCurrentItem(with: item)
    }
    
    private func prepareNext() {
        if audioPlayer == nil { return }
        if currentIndex == 0 { return }
        if currentIndex >= audioUrls.count - 1 {
            currentIndex = 0
        }else {
            currentIndex += 1
        }
        
        replacePlayerItem()
    }
    
    private func setAudio(currentTime: Double, totalTime: Double) {
        
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
        
        if keyPath == "status", let playerItem = object as? AVPlayerItem {
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
    }
    
    public func set(audioUrls: [URL]) {
        self.audioUrls = audioUrls
        setAudioPlayer()
    }
    
    @objc public func play() {
        if audioUrls.count <= 0 { return }
        if audioPlayer?.status != .readyToPlay { return }
        if audioPlayer == nil {
            setAudioPlayer()
        }else {
            audioPlayer?.play()
        }
        isPlaying = true
    }
    
    @objc public func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }
    
    @objc public func playNext() {
        if audioPlayer == nil { return }
        
        if currentIndex >= audioUrls.count - 1 {
            currentIndex = 0
        }else {
            currentIndex += 1
        }
        
        replacePlayerItem()
        isPlaying = true
    }
    
    @objc public func playPrevious() {
        if audioPlayer == nil { return }
        
        if currentIndex <= 0 {
            currentIndex = audioUrls.count - 1
        }else {
            currentIndex -= 1
        }
        
        replacePlayerItem()
        isPlaying = true
    }
    
    public func seek(to seconds: Double, completionHandler: @escaping (Bool) -> Void) {
        audioPlayer?.seek(to: CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), completionHandler: { (isFinished) in
            completionHandler(isFinished)
        })
    }
    
    deinit {
        audioPlayer?.currentItem?.removeObserver(self, forKeyPath: "status")
        audioPlayer?.pause()
        audioPlayer?.removeTimeObserver(self)
        audioPlayer = nil
        
        MPRemoteCommandCenter.shared().playCommand.removeTarget(self, action: #selector(play))
        MPRemoteCommandCenter.shared().pauseCommand.removeTarget(self, action: #selector(pause))
        MPRemoteCommandCenter.shared().nextTrackCommand.removeTarget(self, action: #selector(playNext))
        MPRemoteCommandCenter.shared().previousTrackCommand.removeTarget(self, action: #selector(playPrevious))
        
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
