//
//  SensorContactState.swift
//  HealthScan
//
//  Represents the real-time finger placement and sensor convergence state.
//

import Foundation

/// Real-time contact and signal acquisition state of the optical PPG sensor.
enum SensorContactState: String, Sendable {
    case noFinger = "Place finger over camera"
    case calibrating = "Calibrating sensor..."
    case measuring = "Measuring"
}
