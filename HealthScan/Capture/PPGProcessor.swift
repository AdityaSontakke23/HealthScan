//
//  PPGProcessor.swift
//  ClimbPulse
//
//  Signal processing for PPG data: band-pass filtering and peak detection for BPM estimation.
//

import Foundation
import Accelerate

/// Processes raw PPG samples to extract heart rate (BPM) and assess signal quality.
final class PPGProcessor: Sendable {
    
    // MARK: - Configuration
    
    /// Expected heart rate range (40-200 BPM → 0.67-3.33 Hz)
    let minHeartRateHz: Double = 0.67
    let maxHeartRateHz: Double = 3.33
    
    /// Window size for BPM calculation (in seconds)
    let windowSeconds: Double = 10.0
    
    /// Minimum samples needed for reliable BPM estimation
    let minSamplesForBPM: Int = 100
    
    // MARK: - Public Methods
    
    /// Calculate BPM from recent PPG samples using peak detection.
    func calculateBPM(from samples: [PPGSample], sampleRate: Double) -> Int? {
        guard samples.count >= minSamplesForBPM else { return nil }
        
        let windowSamples = getRecentWindow(samples: samples, windowSeconds: windowSeconds)
        guard windowSamples.count >= minSamplesForBPM else { return nil }
        
        let values = preprocess(signal: windowSamples.map { $0.value })
        let filtered = bandPassFilter(signal: values, sampleRate: sampleRate)
        let peaks = detectPeaks(in: filtered)
        
        guard peaks.count >= 2 else { return nil }
        
        let intervals = calculateIntervals(peaks: peaks, sampleRate: sampleRate)
        guard !intervals.isEmpty else { return nil }
        
        let medianInterval = median(intervals)
        let bpm = Int(60.0 / medianInterval)
        
        guard bpm >= 40 && bpm <= 200 else { return nil }
        return bpm
    }
    
    /// Assess signal quality based on variance and peak regularity.
    func assessQuality(samples: [PPGSample], sampleRate: Double) -> SignalQuality {
        guard samples.count >= minSamplesForBPM else { return .noisy }
        
        let values = preprocess(signal: samples.map { $0.value })
        let filtered = bandPassFilter(signal: values, sampleRate: sampleRate)
        let peaks = detectPeaks(in: filtered)
        
        let duration = samples.last!.timestamp - samples.first!.timestamp
        let expectedMinPeaks = Int(duration * 0.5)
        let expectedMaxPeaks = Int(duration * 3.5)
        
        guard peaks.count >= expectedMinPeaks && peaks.count <= expectedMaxPeaks else {
            return .noisy
        }
        
        let intervals = calculateIntervals(peaks: peaks, sampleRate: sampleRate)
        guard intervals.count >= 3 else { return .noisy }
        
        let meanInterval = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - meanInterval, 2) }.reduce(0, +) / Double(intervals.count)
        let stdDev = sqrt(variance)
        let cv = stdDev / meanInterval
        
        return cv < 0.25 ? .good : .noisy
    }
    
    /// Downsample PPG data for storage (reduce to ~100 points).
    func downsample(samples: [PPGSample], targetCount: Int = 100) -> [Double] {
        guard samples.count > targetCount else {
            return samples.map { $0.value }
        }
        
        let step = Double(samples.count) / Double(targetCount)
        var result: [Double] = []
        
        for i in 0..<targetCount {
            let index = Int(Double(i) * step)
            result.append(samples[index].value)
        }
        
        return result
    }
    
    /// Provide a filtered copy of the most recent window for on-screen display.
    func filteredForDisplay(
        samples: [PPGSample],
        sampleRate: Double,
        windowSeconds: Double = 6.0
    ) -> [PPGSample] {
        let window = getRecentWindow(samples: samples, windowSeconds: windowSeconds)
        guard !window.isEmpty else { return [] }
        
        let preprocessed = preprocess(signal: window.map { $0.value })
        let filtered = bandPassFilter(signal: preprocessed, sampleRate: sampleRate)
        
        return zip(window, filtered).map { sample, filteredValue in
            PPGSample(timestamp: sample.timestamp, value: filteredValue)
        }
    }
    
    /// Clean the full-length signal for storage/plotting (detrend + band-pass).
    func cleanedSignal(samples: [PPGSample], sampleRate: Double) -> [PPGSample] {
        guard !samples.isEmpty else { return [] }
        let preprocessed = preprocess(signal: samples.map { $0.value })
        let filtered = bandPassFilter(signal: preprocessed, sampleRate: sampleRate)
        return zip(samples, filtered).map { PPGSample(timestamp: $0.timestamp, value: $1) }
    }
    
    /// Compute rMSSD (root mean square of successive RR interval differences) in milliseconds.
    /// Applies cardiac band-pass filtering and calculates differences between strictly consecutive intervals.
    func calculateHRV(samples: [PPGSample], sampleRate: Double) -> Double? {
        guard samples.count >= minSamplesForBPM else { return nil }
        
        let preprocessed = preprocess(signal: samples.map { $0.value })
        let filtered = bandPassFilter(signal: preprocessed, sampleRate: sampleRate)
        let peaks = detectPeaks(in: filtered)
        guard peaks.count >= 3 else { return nil }
        
        var diffs: [Double] = []
        for i in 1..<(peaks.count - 1) {
            let tPrev = samples[peaks[i - 1]].timestamp
            let tCurr = samples[peaks[i]].timestamp
            let tNext = samples[peaks[i + 1]].timestamp
            
            let rr1 = (tCurr - tPrev) * 1000.0  // ms
            let rr2 = (tNext - tCurr) * 1000.0  // ms
            
            // Both intervals must be physiologically valid (300-1500 ms, 40-200 BPM)
            if rr1 >= 300 && rr1 <= 1500 && rr2 >= 300 && rr2 <= 1500 {
                let diff = rr2 - rr1
                diffs.append(diff)
            }
        }
        
        guard !diffs.isEmpty else { return nil }
        let sumSquaredDiff = diffs.reduce(0.0) { $0 + ($1 * $1) }
        return sqrt(sumSquaredDiff / Double(diffs.count))
    }
    
    /// Estimate respiratory rate (breaths/min) from low-frequency PPG respiratory baseline modulation (0.15-0.40 Hz).
    func calculateRespiratoryRate(samples: [PPGSample], sampleRate: Double) -> Int? {
        guard samples.count >= minSamplesForBPM else { return nil }
        let detrended = removeLinearTrend(samples.map { $0.value })
        // Low-pass / band-pass around respiratory frequencies using moving averages
        let shortWindow = max(3, Int(sampleRate * 1.2))
        let longWindow = max(5, Int(sampleRate * 5.0))
        let smoothed = movingAverage(signal: detrended, windowSize: shortWindow)
        let baseline = movingAverage(signal: smoothed, windowSize: longWindow)
        let respWave = zip(smoothed, baseline).map { $0 - $1 }
        
        // Count positive zero-crossings
        var crossings = 0
        for i in 1..<respWave.count {
            if respWave[i - 1] < 0 && respWave[i] >= 0 {
                crossings += 1
            }
        }
        let duration = samples.last!.timestamp - samples.first!.timestamp
        guard duration >= 8.0 else { return 15 }
        let brpm = Int(round((Double(crossings) / duration) * 60.0))
        return min(max(brpm, 10), 24)
    }
    
    /// Calculate Stress Score (1-100, lower is calmer) from BPM and rMSSD HRV.
    func calculateStressScore(bpm: Int, hrvMs: Double?) -> Int {
        let hrv = hrvMs ?? 35.0
        // Normalize BPM contribution (50 BPM -> 0, 110 BPM -> 100)
        let bpmNorm = min(max((Double(bpm) - 50.0) / 60.0, 0.0), 1.0) * 100.0
        // Normalize HRV contribution (80 ms -> 0 stress, 15 ms -> 100 stress)
        let hrvStress = (1.0 - min(max((hrv - 15.0) / 65.0, 0.0), 1.0)) * 100.0
        let combined = Int(round(0.45 * bpmNorm + 0.55 * hrvStress))
        return min(max(combined, 8), 96)
    }
    
    /// Calculate Readiness / Recovery Score (1-100, higher is better) from BPM, HRV, and Stress.
    func calculateReadinessScore(bpm: Int, hrvMs: Double?, stressScore: Int) -> Int {
        let hrv = hrvMs ?? 38.0
        let hrvBonus = min(max((hrv - 20.0) / 60.0, 0.0), 1.0) * 35.0
        let stressInverse = Double(100 - stressScore) * 0.65
        let score = Int(round(hrvBonus + stressInverse))
        return min(max(score, 15), 99)
    }
}
