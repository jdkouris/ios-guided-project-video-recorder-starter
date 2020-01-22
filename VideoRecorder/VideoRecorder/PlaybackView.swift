//
//  PlaybackView.swift
//  VideoRecorder
//
//  Created by John Kouris on 1/21/20.
//  Copyright © 2020 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class PlaybackView: UIView {

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

}
