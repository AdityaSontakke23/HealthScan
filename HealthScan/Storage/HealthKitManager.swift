//
//  HealthKitManager.swift
//  HealthScan
//
//  Writes BPM and HRV to Apple Health. Offline only — no networking.
//

import Foundation
import HealthKit

@MainActor
final class HealthKitManager: Sendable {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()
    
    private var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    
    private let writeTypes: Set<HKSampleType> = [
        HKQuantityType(.heartRate),
        HKQuantityType(.heartRateVariabilitySDNN)
    ]
    
    /// Request HealthKit write authorization. Call once on first save.
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: [])
            return true
        } catch {
            return false
        }
    }
    
    /// Write a Measurement's BPM and optionally HRV to HealthKit.
    func export(_ measurement: Measurement) async {
        guard isAvailable else { return }
        
        let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
        let bpmQuantity = HKQuantity(unit: heartRateUnit, doubleValue: Double(measurement.bpm))
        let bpmSample = HKQuantitySample(
            type: HKQuantityType(.heartRate),
            quantity: bpmQuantity,
            start: measurement.timestamp,
            end: measurement.timestamp
        )
        
        var samples: [HKSample] = [bpmSample]
        
        if let hrv = measurement.hrvMs {
            // HealthKit uses SDNN for HRV; rMSSD is a valid approximation to store here
            let hrvQuantity = HKQuantity(unit: HKUnit.secondUnit(with: .milli), doubleValue: hrv)
            let hrvSample = HKQuantitySample(
                type: HKQuantityType(.heartRateVariabilitySDNN),
                quantity: hrvQuantity,
                start: measurement.timestamp,
                end: measurement.timestamp
            )
            samples.append(hrvSample)
        }
        
        do {
            try await store.save(samples)
        } catch {
            print("HealthKit export failed: \(error)")
        }
    }
}
