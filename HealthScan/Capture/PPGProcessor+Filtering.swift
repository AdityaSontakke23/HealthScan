//
//  PPGProcessor+Filtering.swift
//  ClimbPulse
//
//  Signal filtering, baseline correction, and peak detection algorithms.
//

import Foundation
import Accelerate

// MARK: - Internal Signal Processing Methods

extension PPGProcessor {
    
    /// Get samples from the most recent window.
    func getRecentWindow(samples: [PPGSample], windowSeconds: Double) -> [PPGSample] {
        guard let lastTimestamp = samples.last?.timestamp else { return [] }
        let cutoff = lastTimestamp - windowSeconds
        return samples.filter { $0.timestamp >= cutoff }
    }
    
    /// Remove spikes and normalize amplitude ahead of filtering.
    func preprocess(signal: [Double]) -> [Double] {
        let detrended = removeLinearTrend(signal)
        let medianSmoothed = medianFilter(signal: detrended, windowSize: 5)
        let clipped = softClip(signal: medianSmoothed, limitStd: 3.5)
        return normalize(signal: clipped)
    }
    
    /// Remove slow linear drift to keep baseline stable.
    func removeLinearTrend(_ signal: [Double]) -> [Double] {
        guard signal.count > 2 else { return signal }
        let n = Double(signal.count)
        let meanX = (n - 1) / 2.0
        let meanY = signal.reduce(0, +) / n
        
        var numerator = 0.0
        var denominator = 0.0
        for (i, y) in signal.enumerated() {
            let x = Double(i)
            numerator += (x - meanX) * (y - meanY)
            denominator += (x - meanX) * (x - meanX)
        }
        guard denominator > 0 else { return signal }
        let slope = numerator / denominator
        let intercept = meanY - slope * meanX
        
        return signal.enumerated().map { index, y in
            let x = Double(index)
            return y - (slope * x + intercept)
        }
    }
    
    /// Band-pass filter using single-pole IIR tuned for heart-rate band (~0.6-4 Hz).
    func bandPassFilter(signal: [Double], sampleRate: Double) -> [Double] {
        guard signal.count > 4 else { return signal }
        
        let lowCutHz = max(0.6, minHeartRateHz * 0.9)
        let highCutHz = min(4.0, maxHeartRateHz * 1.2)
        let dt = 1.0 / max(sampleRate, 1.0)
        
        // High-pass
        let rcHigh = 1.0 / (2 * .pi * lowCutHz)
        let alphaHigh = rcHigh / (rcHigh + dt)
        var highPassed = Array(repeating: 0.0, count: signal.count)
        for i in 1..<signal.count {
            highPassed[i] = alphaHigh * (highPassed[i-1] + signal[i] - signal[i-1])
        }
        
        // Low-pass
        let rcLow = 1.0 / (2 * .pi * highCutHz)
        let alphaLow = dt / (rcLow + dt)
        var bandPassed = Array(repeating: highPassed.first ?? 0.0, count: signal.count)
        for i in 1..<signal.count {
            bandPassed[i] = bandPassed[i-1] + alphaLow * (highPassed[i] - bandPassed[i-1])
        }
        
        let smoothWindow = max(3, Int(sampleRate / 12.0))
        return movingAverage(signal: bandPassed, windowSize: smoothWindow)
    }
    
    /// Calculate moving average of signal.
    func movingAverage(signal: [Double], windowSize: Int) -> [Double] {
        guard signal.count >= windowSize else { return signal }
        
        var result: [Double] = []
        let halfWindow = windowSize / 2
        
        for i in 0..<signal.count {
            let start = max(0, i - halfWindow)
            let end = min(signal.count - 1, i + halfWindow)
            let window = Array(signal[start...end])
            let avg = window.reduce(0, +) / Double(window.count)
            result.append(avg)
        }
        
        return result
    }
    
    /// Median filter to suppress impulsive noise.
    func medianFilter(signal: [Double], windowSize: Int) -> [Double] {
        guard signal.count > windowSize && windowSize >= 3 else { return signal }
        let half = windowSize / 2
        var output: [Double] = []
        
        for i in 0..<signal.count {
            let start = max(0, i - half)
            let end = min(signal.count - 1, i + half)
            let window = Array(signal[start...end]).sorted()
            output.append(window[window.count / 2])
        }
        
        return output
    }
    
    /// Normalize signal to zero-mean unit-variance to stabilize peak detection.
    func normalize(signal: [Double]) -> [Double] {
        guard !signal.isEmpty else { return signal }
        let mean = signal.reduce(0, +) / Double(signal.count)
        let variance = signal.map { pow($0 - mean, 2) }.reduce(0, +) / Double(signal.count)
        let std = sqrt(variance)
        guard std > 0.0001 else { return signal.map { _ in 0 } }
        return signal.map { ($0 - mean) / std }
    }
    
    /// Soft clip extreme values using a smooth tanh limiter to reduce motion spikes.
    func softClip(signal: [Double], limitStd: Double) -> [Double] {
        guard !signal.isEmpty else { return signal }
        let mean = signal.reduce(0, +) / Double(signal.count)
        let variance = signal.map { pow($0 - mean, 2) }.reduce(0, +) / Double(signal.count)
        let std = max(sqrt(variance), 1e-6)
        let cap = limitStd * std
        return signal.map { sample in
            let centered = sample - mean
            let limited = cap * tanh(centered / cap)
            return mean + limited
        }
    }
    
    /// Detect peaks in signal using local maxima detection with adaptive threshold.
    func detectPeaks(in signal: [Double]) -> [Int] {
        guard signal.count > 4 else { return [] }
        
        var peaks: [Int] = []
        let mean = signal.reduce(0, +) / Double(signal.count)
        let variance = signal.map { pow($0 - mean, 2) }.reduce(0, +) / Double(signal.count)
        let threshold = mean + 0.3 * sqrt(variance)
        
        for i in 2..<(signal.count - 2) {
            let current = signal[i]
            if current > signal[i-1] && current > signal[i-2] &&
               current > signal[i+1] && current > signal[i+2] &&
               current > threshold {
                
                if let lastPeak = peaks.last {
                    if i - lastPeak > 5 {
                        peaks.append(i)
                    }
                } else {
                    peaks.append(i)
                }
            }
        }
        
        return peaks
    }
    
    /// Calculate time intervals between consecutive peaks.
    func calculateIntervals(peaks: [Int], sampleRate: Double) -> [Double] {
        guard peaks.count >= 2 else { return [] }
        
        var intervals: [Double] = []
        for i in 1..<peaks.count {
            let sampleDiff = peaks[i] - peaks[i-1]
            let timeDiff = Double(sampleDiff) / sampleRate
            
            if timeDiff >= 0.3 && timeDiff <= 1.5 {
                intervals.append(timeDiff)
            }
        }
        
        return intervals
    }
    
    /// Calculate median of an array.
    func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let count = sorted.count
        
        if count % 2 == 0 {
            return (sorted[count/2 - 1] + sorted[count/2]) / 2.0
        } else {
            return sorted[count/2]
        }
    }
}
