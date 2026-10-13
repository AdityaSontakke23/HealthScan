//
//  CameraManager+OutputDelegate.swift
//  ClimbPulse
//
//  AVCaptureVideoDataOutput sample buffer delegate and frame signal extraction.
//

import Foundation
@preconcurrency import AVFoundation
import CoreVideo

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /// Process each video frame to extract PPG signal and detect finger contact.
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let (ppgValue, isCovered) = extractPPGSignal(from: sampleBuffer) else { return }
        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        Task { @MainActor in
            self.handleFrame(ppgValue: ppgValue, isCovered: isCovered, pts: pts)
        }
    }
    
    /// Coordinate finger contact, dynamic exposure convergence, and sample ingestion on MainActor.
    @MainActor
    func handleFrame(ppgValue: Double, isCovered: Bool, pts: CMTime) {
        guard isRecording else { return }
        
        // Reject uncovered sensor and ambient light; unlock exposure so it re-calibrates on next contact
        if !isCovered {
            if hasLockedExposure {
                hasLockedExposure = false
                lockExposureAndWhiteBalance(locked: false)
            }
            contactState = .noFinger
            calibrationFramesCount = 0
            return
        }
        
        // Dynamic exposure convergence: let auto-exposure settle on illuminated tissue for 15 frames (~0.5s)
        if !hasLockedExposure {
            contactState = .calibrating
            calibrationFramesCount += 1
            if calibrationFramesCount >= 15 {
                lockExposureAndWhiteBalance()
                hasLockedExposure = true
                contactState = .measuring
                recordingState.startPTS = pts
            }
            return
        }
        
        contactState = .measuring
        guard let startPTS = recordingState.startPTS else {
            recordingState.startPTS = pts
            return
        }
        
        let relative = CMTimeSubtract(pts, startPTS)
        let timestamp = CMTimeGetSeconds(relative)
        appendSample(value: ppgValue, timestamp: timestamp)
    }
    
    /// Append a smoothed PPG sample and update display at a throttled rate to prevent MainActor saturation.
    @MainActor
    func appendSample(value: Double, timestamp: Double) {
        let smoothed = smoothPPGValue(value)
        let limited = clampJump(smoothed)
        let sample = PPGSample(timestamp: timestamp, value: limited)
        samples.append(sample)
        
        // Throttled display filter (every 3 frames, ~10 Hz) prevents MainActor hitching
        frameCounter += 1
        if frameCounter % 3 == 0 {
            let sampleRate = estimatedSampleRate()
            filteredSamples = ppgProcessor.filteredForDisplay(
                samples: samples,
                sampleRate: sampleRate
            )
        }
        updateBPMIfNeeded()
    }
    
    /// Exponential smoothing for PPG values to suppress frame-to-frame noise.
    @MainActor
    func smoothPPGValue(_ newValue: Double) -> Double {
        let clamped = min(max(newValue, 0), 255)
        
        guard let previous = previousRedValue else {
            previousRedValue = clamped
            return clamped
        }
        
        // Heavier smoothing on sudden jumps (likely motion noise)
        let jump = abs(clamped - previous)
        let alpha: Double = jump > 60 ? 0.18 : 0.32
        let blended = previous * (1 - alpha) + clamped * alpha
        previousRedValue = blended
        return blended
    }
    
    /// Cap abrupt jumps between consecutive samples to reduce motion spikes.
    @MainActor
    func clampJump(_ value: Double, maxDelta: Double = 18.0) -> Double {
        guard let prev = samples.last?.value else {
            return value
        }
        let delta = value - prev
        if abs(delta) <= maxDelta {
            return value
        }
        return prev + (delta > 0 ? maxDelta : -maxDelta)
    }
    
    /// Extract green channel value and verify tissue transillumination (finger coverage).
    nonisolated func extractPPGSignal(from sampleBuffer: CMSampleBuffer) -> (green: Double, isCovered: Bool)? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }

        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        var greenSum: Int = 0
        var redSum: Int = 0
        var validPixelCount: Int = 0

        let step = 2  // every other pixel is enough at .vga640x480 preset
        for y in stride(from: 0, to: height, by: step) {
            let rowStart = y * bytesPerRow
            for x in stride(from: 0, to: width, by: step) {
                let offset = rowStart + x * 4
                let green = Int(buffer[offset + 1])
                let red = Int(buffer[offset + 2])

                greenSum += green
                redSum += red
                validPixelCount += 1
            }
        }

        guard validPixelCount > 0 else { return nil }

        let count = Double(validPixelCount)
        let avgGreen = Double(greenSum) / count
        let avgRed = Double(redSum) / count

        // Tissue transillumination check: red light strongly penetrates finger tissue (red > 80)
        // and is distinctly dominant over green channel (red > green * 1.15)
        let isCovered = avgRed > 80 && (avgRed > avgGreen * 1.15)
        return (avgGreen, isCovered)
    }
}
