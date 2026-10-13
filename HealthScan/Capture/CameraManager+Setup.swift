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
        
        // Register for thermal state changes so we can warn and pause mid-recording
        NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                let state = ProcessInfo.processInfo.thermalState
                if state == .serious || state == .critical {
                    self.thermalWarningActive = true
                    if self.isRecording {
                        self.errorMessage = "Device is overheating. Recording stopped."
                        self.stopRecording()
                    }
                } else {
                    self.thermalWarningActive = false
                }
            }
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
        if camera.isExposureModeSupported(.continuousAutoExposure) {
            camera.exposureMode = .continuousAutoExposure
        }
        if camera.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
            camera.whiteBalanceMode = .continuousAutoWhiteBalance
        }
        if camera.isAutoFocusRangeRestrictionSupported {
            camera.autoFocusRangeRestriction = .near
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
                // 0.15 is sufficient for PPG capture and prevents skin heating
                // and thermal throttling. Never exceed 0.3 for sustained contact use.
                let safeLevel = min(0.15, AVCaptureDevice.maxAvailableTorchLevel)
                try device.setTorchModeOn(level: safeLevel)
            }
            device.unlockForConfiguration()
        } catch {
            print("Torch error: \(error)")
        }
    }
    
    /// Dynamically lock or unlock exposure and white balance based on finger contact.
    nonisolated func lockExposureAndWhiteBalance(locked: Bool = true) {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        do {
            try device.lockForConfiguration()
            let expMode: AVCaptureDevice.ExposureMode = locked ? .locked : .continuousAutoExposure
            let wbMode: AVCaptureDevice.WhiteBalanceMode = locked ? .locked : .continuousAutoWhiteBalance
            if device.isExposureModeSupported(expMode) { device.exposureMode = expMode }
            if device.isWhiteBalanceModeSupported(wbMode) { device.whiteBalanceMode = wbMode }
            device.unlockForConfiguration()
        } catch {
            print("Exposure configuration error: \(error)")
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
        
        // Compute rMSSD HRV, Respiratory Rate, Stress Score, and Readiness Score
        let hrv = ppgProcessor.calculateHRV(samples: cleaned, sampleRate: sampleRate)
        lastHRVms = hrv
        let respRate = ppgProcessor.calculateRespiratoryRate(samples: trimmed, sampleRate: sampleRate)
        let stress = ppgProcessor.calculateStressScore(bpm: finalBPM, hrvMs: hrv)
        let readiness = ppgProcessor.calculateReadinessScore(bpm: finalBPM, hrvMs: hrv, stressScore: stress)
        
        let measurement = Measurement(
            userId: Self.getUserId(),
            duration: duration,
            sampleRate: sampleRate,
            bpm: finalBPM,
            quality: quality,
            ppgData: downsampledPPG,
            hrvMs: hrv,
            stressScore: stress,
            respiratoryRate: respRate,
            readinessScore: readiness
        )
        onRecordingComplete?(measurement)
    }
}
