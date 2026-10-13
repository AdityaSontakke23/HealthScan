//
//  CameraManager+Session.swift
//  HealthScan
//
//  Session timing, sampling rate estimation, countdown orchestration, and Simulator demo mode.
//

import Foundation
import CoreMedia

extension CameraManager {
    
    // MARK: - Session Helpers
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                // Pause countdown automatically whenever the finger is lifted or re-calibrating
                guard self.contactState == .measuring else { return }
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
    
    func beginCountdownFromNow() {
        countdownStarted = true
        self.recordingState.startTime = Date()
        self.detectionStartTimestamp = samples.last?.timestamp
        self.timeRemaining = recordingDuration
        self.startTimer()
    }
    
    // MARK: - Simulator Demo Mode
    
    /// Generates a realistic 30 FPS physiological PPG waveform when running in the iOS Simulator.
    func startSimulatorDemo() {
        isRecording = true
        thermalWarningActive = false
        let startDate = Date()
        
        simulatorTimer?.invalidate()
        simulatorTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                guard self.isRecording else { return }
                let elapsed = Date().timeIntervalSince(startDate)
                let pts = CMTime(seconds: elapsed, preferredTimescale: 600)
                
                // Realistic pulse (~72 BPM = 1.2 Hz) with respiratory HRV modulation (0.25 Hz)
                let phase = 2.0 * .pi * 1.2 * elapsed + 0.35 * sin(2.0 * .pi * 0.25 * elapsed)
                let systolic = 14.0 * sin(phase)
                let dicrotic = 4.5 * sin(2.0 * phase - 0.8)
                let greenValue = 130.0 + systolic + dicrotic
                
                self.handleFrame(ppgValue: greenValue, isCovered: true, pts: pts)
            }
        }
    }
}
