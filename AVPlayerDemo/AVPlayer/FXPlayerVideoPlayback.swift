//
//  FXPlayerMediaPlayback.swift
//  AVPlayerDemo
//
//  Created by Dong on 2019/5/13.
//  Copyright © 2019 dong. All rights reserved.
//

import UIKit

public protocol FXPlayerVideoPlayback {
    
    var currentTime: Double { get }
    
    var totalTime: Double { get }
    
    var view: UIView { get }
    
    var isReadyToPlay: Bool { get }
    
    var isAutoPlay: Bool { get set }
    
    var isPlaying: Bool { get }
    
    func play()
    
    func pause()
}
