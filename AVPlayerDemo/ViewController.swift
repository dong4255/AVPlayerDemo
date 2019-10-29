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
    
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    
    @IBOutlet weak var anotherTimeSlider: FXSlider!
    
    
    private let audioPlayer = FXAudioPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let urlStringArray = ["http://101.227.216.151/amobile.music.tc.qq.com/C400002ebNvY22rDBy.m4a?guid=9677210256&vkey=9D6659CC4431543ABD3D1D81C47D17A53CD2CAA1926528F3085EC0A746ABFD24D4A27DB93029854E3DA5A4B30AFCF3E6F92D988655C80105&uin=0&fromtag=66",
            "http://101.227.216.159/amobile.music.tc.qq.com/C4000031nsKs0yyZs0.m4a?guid=9677210256&vkey=F8B99B535EDD279F96CAA7E1B688E3AA8DA3099B3BA9B24164AE86C3967C54641522D32DC2C9EB5FA9473F0610B0E686D7CFA415F31E5316&uin=5619&fromtag=66",
            "http://101.227.216.146/amobile.music.tc.qq.com/C400000b7aaR0vOevG.m4a?guid=9677210256&vkey=BF817C2181EA9B015BEC875CD7FCB1C435536E9CE5A85F0AEE71D259556DFAA86EA16D763223063E037B05E628A2B806D45F3693F5048333&uin=5619&fromtag=66"]
        var urlArray = [URL]()
        for urlString in urlStringArray {
            if let url = URL(string: urlString) {
                urlArray.append(url)
            }
        }
        audioPlayer.set(audioUrls: urlArray)
        audioPlayer.delegate = self
        audioPlayer.playStatus = {[weak self] (isPlaying) in
            self?.playButton.setImage(isPlaying ? #imageLiteral(resourceName: "pause.png") : #imageLiteral(resourceName: "play.png"), for: .normal)
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
