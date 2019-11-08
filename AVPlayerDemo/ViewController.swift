//
//  ViewController.swift
//  AVPlayerDemo
//
//  Created by Dong on 2019/5/8.
//  Copyright © 2019 dong. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var activityIV: UIActivityIndicatorView!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    
    @IBOutlet weak var anotherTimeSlider: FXSlider!
    
    
    private let audioPlayer = FXAudioPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let urlStringArray = ["https://sharefs.yun.kugou.com/201910301117/8d40a6468a1169acd90f9d2a50437b51/G145/M04/1F/09/cZQEAFvJOg6ASldLAE0mYOFr70E210.mp3"]
        
        var urlArray = [URL]()
        for urlString in urlStringArray {
            if let url = URL(string: urlString) {
                urlArray.append(url)
            }
        }
        audioPlayer.set(audioUrls: urlArray)
        audioPlayer.delegate = self
        audioPlayer.playStatus = {[weak self] (status) in
            if status == .loading {
                self?.playButton.isHidden = true
                self?.activityIV.startAnimating()
            }else {
                self?.activityIV.stopAnimating()
                self?.playButton.isHidden = false
                let isPlaying = status == .playing
                self?.playButton.setImage(isPlaying ? #imageLiteral(resourceName: "pause.png") : #imageLiteral(resourceName: "play.png"), for: .normal)
            }
        }
        
        timeSlider.addTarget(self, action: #selector(sliderTouchEndAction(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        anotherTimeSlider.addTarget(self, action: #selector(anotherSliderValueChangedAction(_:)), for: .valueChanged)
        anotherTimeSlider.addTarget(self, action: #selector(anotherSliderTouchEndAction(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
    }
    
    @IBAction func playButtonAction(_ sender: UIButton) {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        }else {
            audioPlayer.play()
        }
    }
    
    
    @IBAction func nextButtonAction(_ sender: UIButton) {
        audioPlayer.playNext()
    }
    
    @IBAction func lastButtonAction(_ sender: UIButton) {
        audioPlayer.playPrevious()
    }
    
    @IBAction func sliderValueChangedAction(_ sender: UISlider) {
        audioPlayer.isStartSeek = true
        currentTimeLabel.text = Double(sender.value).formatToTime()
    }
    
    @objc private func sliderTouchEndAction(_ sender: UISlider) {
        audioPlayer.seek(to: Double(sender.value)) {[weak self] isFinished in
            if isFinished {
                self?.audioPlayer.isStartSeek = false
            }
        }
    }
    
    
    @objc private func anotherSliderValueChangedAction(_ sender: FXSlider) {
        audioPlayer.isStartSeek = true
        currentTimeLabel.text = Double(sender.value).formatToTime()
    }
    
    @objc private func anotherSliderTouchEndAction(_ sender: FXSlider) {
        audioPlayer.seek(to: Double(sender.value)) {[weak self] isFinished in
            if isFinished {
                self?.audioPlayer.isStartSeek = false
            }
        }
    }
    
    @IBAction func rightBarItemAction(_ sender: UIBarButtonItem) {
        self.navigationController?.pushViewController(VideoViewController(), animated: true)
    }
    
    
}

extension ViewController : FXAudioPlayerDelegate {
    
    func audioPlayer(_ player: FXAudioPlayer, currentTime: Double, totalTime: Double) {
//        print(currentTime)
        timeSlider.maximumValue = Float(totalTime)
        anotherTimeSlider.maximumValue = totalTime
        if !audioPlayer.isStartSeek {
            timeSlider.value = Float(currentTime)
            anotherTimeSlider.value = currentTime
            currentTimeLabel.text = currentTime.formatToTime()
        }
        totalTimeLabel.text = totalTime.formatToTime()
    }

}
