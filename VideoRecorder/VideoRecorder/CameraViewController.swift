//
//  CameraViewController.swift
//  VideoRecorder
//
//  Created by Paul Solt on 10/2/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    lazy private var captureSession = AVCaptureSession()
    lazy private var fileOutput = AVCaptureMovieFileOutput()
    var player: AVPlayer!
    var playerView: PlaybackView!

    @IBOutlet var recordButton: UIButton!
    @IBOutlet var cameraView: CameraPreviewView!


	override func viewDidLoad() {
		super.viewDidLoad()
        setUpCamera()
        
		// Resize camera preview to fill the entire screen
		cameraView.videoPlayerView.videoGravity = .resizeAspectFill
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        view.addGestureRecognizer(tapGesture)
	}
    
    @objc func handleTapGesture(_ tapGesture: UITapGestureRecognizer) {
        print("tap")
        switch(tapGesture.state) {
        case .ended:
            playRecording()
        default:
            print("handled other states: \(tapGesture.state)")
        }
    }
    
    func playRecording() {
        if let player = player {
            player.seek(to: CMTime.zero)
            player.play()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession.startRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession.stopRunning()
    }
    
    private func setUpCamera() {
        let camera = bestCamera()
        
        captureSession.beginConfiguration()
        guard let cameraInput = try? AVCaptureDeviceInput(device: camera) else {
            fatalError("Can't create an input from the camera, do something better than crashing")
        }
        
        guard captureSession.canAddInput(cameraInput) else {
            fatalError("This session can't handle this type of input: \(cameraInput)")
        }
        
        captureSession.addInput(cameraInput)
        
        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        }
        
        let microphone = bestAudio()
        guard let audioInput = try? AVCaptureDeviceInput(device: microphone) else {
            fatalError("Can't create input from microphone")
        }
        
        guard captureSession.canAddInput(audioInput) else {
            fatalError("Can't add audio input")
        }
        captureSession.addInput(audioInput)
        
        guard captureSession.canAddOutput(fileOutput) else {
            fatalError("Cannot record to disk")
        }
        captureSession.addOutput(fileOutput)
        
        captureSession.commitConfiguration()
        
        cameraView.session = captureSession
    }
    
    private func bestCamera() -> AVCaptureDevice {
        if let device = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
            return device
        }
        
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return device
        }
        
        fatalError("No cameras on the device (or running it on the iPhone simulator)")
    }

    private func bestAudio() -> AVCaptureDevice {
        if let device = AVCaptureDevice.default(for: .audio) {
            return device
        }
        fatalError("No audio")
    }

    @IBAction func recordButtonPressed(_ sender: Any) {
        toggleRecord()
	}
    
    private func toggleRecord() {
        if fileOutput.isRecording {
            fileOutput.stopRecording()
        } else {
            fileOutput.startRecording(to: newRecordingURL(), recordingDelegate: self)
        }
    }
	
	/// Creates a new file URL in the documents directory
	private func newRecordingURL() -> URL {
		let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withInternetDateTime]

		let name = formatter.string(from: Date())
		let fileURL = documentsDirectory.appendingPathComponent(name).appendingPathExtension("mov")
		return fileURL
	}
    
    private func updateViews() {
        recordButton.isSelected = fileOutput.isRecording
    }
    
    func playMovie(url: URL) {
        if playerView == nil {
            playerView = PlaybackView()
            
            var topRect = self.view.bounds
            topRect.size.height = topRect.height / 4
            topRect.size.width = topRect.width / 4
            topRect.origin.y = view.layoutMargins.top
            
            playerView.frame = topRect
            view.addSubview(playerView)
        }
        
        /*
         Assumption: player is non-nil (because it is an explicitely unwrapped optional)
         
         player?.pause():
            We aren't sure if player exists or not - if this is the first time we run this part, then it won't!
            To prevent it from crashing if it is nil, we swap our assumptions around and place a '?' to make it a regular optional, which won't do anything if it is nil
         
         player = AVPlayer(url: url):
            We are creating a new player right here.
            From this point forward, it will always be non-nil
         
         player.play():
            Because it is explicitely unwrapped, and we know it is not nil, it's safe to use without a '?'
         */
        player?.pause()
        player = AVPlayer(url: url)
        playerView.playerLayer.player = player
        player.play()
    }
    
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        updateViews()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error saving video: \(error)")
        }
        print("Video: \(outputFileURL.path)")
        updateViews()
        
        playMovie(url: outputFileURL)
    }
    
}
