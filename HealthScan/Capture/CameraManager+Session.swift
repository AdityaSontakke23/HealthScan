//
//  CameraManager+Session.swift
//  HealthScan
//
//  Session timing, sampling rate estimation, and countdown orchestration.
//

import Foundation

extension CameraManager {
    
    // MARK: - Session Helpers
    
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
    
    func beginCountdownFromNow() {
        countdownStarted = true
        self.recordingState.startTime = Date()
        self.detectionStartTimestamp = samples.last?.timestamp
        self.timeRemaining = recordingDuration
        self.startTimer()
    }
}
