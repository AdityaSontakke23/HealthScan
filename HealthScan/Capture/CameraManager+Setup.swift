//
//  CameraManager+Setup.swift
//  ClimbPulse
//
//  Camera authorization, capture session configuration, torch control, and user ID management.
//

import Foundation
@preconcurrency import AVFoundation
import UIKit

extension CameraManager {
    
    // MARK: - Authorization
    
    /// Request camera authorization.
    func requestAuthorization() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            isAuthorized = false
            errorMessage = "Camera access denied. Please enable in Settings."
        @unknown default:
            isAuthorized = false
        }
    }
    
    // MARK: - Capture Session Setup
    
    /// Set up the capture session with back camera and torch.
    nonisolated func setupCaptureSession() throws -> (AVCaptureSession, AVCaptureVideoDataOutput) {
        let session = AVCaptureSession()
        session.sessionPreset = .vga640x480
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.cameraUnavailable
        }
        
        try camera.lockForConfiguration()
        if camera.isExposureModeSupported(.locked) {
            camera.exposureMode = .locked
        }
        if camera.isWhiteBalanceModeSupported(.locked) {
            camera.whiteBalanceMode = .locked
        }
        camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
        camera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
        camera.unlockForConfiguration()
        
        let input = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(input) else {
            throw CameraError.cannotAddInput
        }
        session.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.setSampleBufferDelegate(self, queue: processingQueue)
        output.alwaysDiscardsLateVideoFrames = false
        
        guard session.canAddOutput(output) else {
            throw CameraError.cannotAddOutput
        }
        session.addOutput(output)
        
        return (session, output)
    }
    
    // MARK: - Torch & Helpers
    
    nonisolated func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            if on {
                let desiredLevel = min(0.6, AVCaptureDevice.maxAvailableTorchLevel)
                try device.setTorchModeOn(level: desiredLevel)
            }
            device.unlockForConfiguration()
        } catch {
            print("Torch error: \(error)")
        }
    }
    
    nonisolated static func getUserId() -> String {
        let key = "climbpulse_user_id"
        if let existingId = UserDefaults.standard.string(forKey: key) {
            return existingId
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }
    
    // MARK: - Measurement Finalization
    
    func processAndSaveMeasurement() {
        guard samples.count > 50 else {
            errorMessage = "Insufficient data collected"
            onRecordingComplete?(nil)
            return
        }
        
        let sampleRate = estimatedSampleRate()
        let trimmed: [PPGSample]
        if let startTs = detectionStartTimestamp {
            trimmed = samples.filter { $0.timestamp >= startTs }
        } else {
            trimmed = samples
        }
        
        guard trimmed.count > 20 else {
            errorMessage = "Insufficient stable data collected"
            onRecordingComplete?(nil)
            return
        }
        
        let cleaned = ppgProcessor.cleanedSignal(samples: trimmed, sampleRate: sampleRate)
        let finalBPM = ppgProcessor.calculateBPM(from: cleaned, sampleRate: sampleRate) ?? currentBPM ?? 0
        let quality = ppgProcessor.assessQuality(samples: cleaned, sampleRate: sampleRate)
        let downsampledPPG = ppgProcessor.downsample(samples: cleaned)
        let duration = cleaned.last!.timestamp - cleaned.first!.timestamp
        
        let measurement = Measurement(
            userId: Self.getUserId(),
            duration: duration,
            sampleRate: sampleRate,
            bpm: finalBPM,
            quality: quality,
            ppgData: downsampledPPG
        )
        onRecordingComplete?(measurement)
    }
}
