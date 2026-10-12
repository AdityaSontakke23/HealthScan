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
    
    /// Process each video frame to extract PPG signal.
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Lazily set the first presentation timestamp to align future frames
        if recordingState.startPTS == nil {
            recordingState.startPTS = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        }
        guard let startPTS = recordingState.startPTS else { return }
        
        // Extract PPG signal from frame using green channel from ROI
        guard let ppgValue = extractPPGSignal(from: sampleBuffer) else { return }
        
        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let relative = CMTimeSubtract(pts, startPTS)
        let timestamp = CMTimeGetSeconds(relative)
        
        Task { @MainActor in
            self.appendSample(value: ppgValue, timestamp: timestamp)
        }
    }
    
    /// Append a smoothed PPG sample on the main actor to avoid cross-thread state mutation.
    @MainActor
    func appendSample(value: Double, timestamp: Double) {
        let smoothed = smoothPPGValue(value)
        let limited = clampJump(smoothed)
        let sample = PPGSample(timestamp: timestamp, value: limited)
        samples.append(sample)
        
        // Refresh filtered copy for UI and quality estimate
        let sampleRate = estimatedSampleRate()
        filteredSamples = ppgProcessor.filteredForDisplay(
            samples: samples,
            sampleRate: sampleRate
        )
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
    
    /// Extract PPG signal from centered ROI using green channel for improved SNR.
    nonisolated func extractPPGSignal(from sampleBuffer: CMSampleBuffer) -> Double? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }

        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        var greenSum: Int = 0
        var validPixelCount: Int = 0

        let step = 2  // every other pixel is enough at .low preset
        for y in stride(from: 0, to: height, by: step) {
            let rowStart = y * bytesPerRow
            for x in stride(from: 0, to: width, by: step) {
                let offset = rowStart + x * 4
                let green = Int(buffer[offset + 1])  // Green channel

                greenSum += green
                validPixelCount += 1
            }
        }

        guard validPixelCount > 0 else { return nil }

        let avgGreen = Double(greenSum) / Double(validPixelCount)
        return avgGreen
    }
}
