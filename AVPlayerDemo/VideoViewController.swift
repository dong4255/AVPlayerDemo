//
//  VideoViewController.swift
//  AVPlayerDemo
//
//  Created by Dong on 2019/5/13.
//  Copyright © 2019 dong. All rights reserved.
//

import UIKit

class VideoViewController: UIViewController {
    
    private let videoPlayer = FXVideoPlayer()
    private let videoView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        videoView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 9 / 16.0)
        videoView.center = view.center
        view.addSubview(videoView)
        
        let urlString = "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/gear2/prog_index.m3u8"
        videoPlayer.set(videoUrl: urlString)
        videoPlayer.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        videoPlayer.view.frame = videoView.bounds
        videoView.addSubview(videoPlayer.view)
        
        
        
    }
    

}
