//
//  CameraManager.swift
//  ClimbPulse
//
//  Manages AVCaptureSession for PPG recording using the back camera with torch.
//  Extracts average green channel values from each frame for heart rate estimation.
//

import Foundation
@preconcurrency import AVFoundation
import UIKit
import Observation

/// Manages camera capture and PPG signal extraction from video frames.
@Observable
@MainActor
class CameraManager: NSObject {
    
    // MARK: - Observable Properties
    
    var isRecording = false
    var currentBPM: Int?
    var samples: [PPGSample] = []
    var filteredSamples: [PPGSample] = []  // Band-passed samples for UI display
    var timeRemaining: Int = 30
    var errorMessage: String?
    var isAuthorized = false
    private(set) var captureSession: AVCaptureSession?
    var signalQuality: SignalQuality = .noisy
    var recordingLength: Int { recordingDuration }
    
    // MARK: - Internal Properties
    
    var videoOutput: AVCaptureVideoDataOutput?
    let sessionQueue = DispatchQueue(label: "com.climbpulse.camera.session")
    let processingQueue = DispatchQueue(label: "com.climbpulse.camera.processing")
    var previousRedValue: Double?
    
    // Thread-safe recording state
    nonisolated let recordingState = RecordingState()
    
    var timer: Timer?
    let recordingDuration: Int = 30
    
    let ppgProcessor = PPGProcessor()
    var lastBPMUpdate: Date = Date()
    let bpmUpdateInterval: TimeInterval = 2.0  // Update BPM every 2 seconds
    var detectionStartTimestamp: Double?
    
    // Start countdown only after BPM detected
    var countdownStarted = false
    
    // Completion handler for when recording finishes
    var onRecordingComplete: ((Measurement?) -> Void)?
    
    // MARK: - Recording Control
    
    /// Start PPG recording session.
    func startRecording() {
        guard isAuthorized else {
            errorMessage = "Camera not authorized"
            return
        }
        
        samples = []
        filteredSamples = []
        currentBPM = nil
        timeRemaining = recordingDuration
        errorMessage = nil
        recordingState.startTime = nil
        recordingState.startPTS = nil
        captureSession = nil
        signalQuality = .noisy
        countdownStarted = false
        previousRedValue = nil
        detectionStartTimestamp = nil
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                let (session, output) = try self.setupCaptureSession()
                self.setTorch(on: true)
                self.recordingState.startTime = Date()
                session.startRunning()
                
                Task { @MainActor in
                    self.captureSession = session
                    self.videoOutput = output
                    self.isRecording = true
                }
            } catch {
                Task { @MainActor in
                    self.errorMessage = "Failed to start camera: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Stop recording and process final results.
    func stopRecording() {
        timer?.invalidate()
        timer = nil
        
        let session = captureSession
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.setTorch(on: false)
            session?.stopRunning()
            self.recordingState.startTime = nil
            self.recordingState.startPTS = nil
            
            Task { @MainActor in
                self.captureSession = nil
                self.isRecording = false
                self.processAndSaveMeasurement()
            }
        }
    }
    
    // MARK: - Signal Processing Helpers
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.stopRecording()
                }
            }
        }
    }
    
    func estimatedSampleRate() -> Double {
        guard samples.count > 1,
              let first = samples.first?.timestamp,
              let last = samples.last?.timestamp else {
            return 30.0
        }
        let duration = last - first
        guard duration > 0 else { return 30.0 }
        return Double(samples.count) / duration
    }
    
    func updateBPMIfNeeded() {
        let now = Date()
        guard now.timeIntervalSince(lastBPMUpdate) >= bpmUpdateInterval else { return }
        lastBPMUpdate = now
        
        let sampleRate = estimatedSampleRate()
        let bpm = ppgProcessor.calculateBPM(from: samples, sampleRate: sampleRate)
        self.currentBPM = bpm
        
        if !samples.isEmpty {
            self.signalQuality = ppgProcessor.assessQuality(samples: samples, sampleRate: sampleRate)
        }
        
        if !countdownStarted, bpm != nil {
            beginCountdownFromNow()
        }
    }
    
    private func beginCountdownFromNow() {
        countdownStarted = true
        self.recordingState.startTime = Date()
        self.detectionStartTimestamp = samples.last?.timestamp
        self.timeRemaining = recordingDuration
        self.startTimer()
    }
}
