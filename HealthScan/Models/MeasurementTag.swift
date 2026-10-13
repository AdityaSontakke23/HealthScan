//
//  MeasurementTag.swift
//  HealthScan
//
//  One-tap state context tag for a completed measurement.
//

import Foundation

enum MeasurementTag: String, CaseIterable, Codable, Sendable {
    case resting = "Resting"
    case postWorkout = "Post-Workout"
    case stressed = "Stressed"
    case morning = "Morning"
    
    var iconName: String {
        switch self {
        case .resting: return "chair.lounge.fill"
        case .postWorkout: return "figure.run"
        case .stressed: return "waveform.path.ecg"
        case .morning: return "sunrise.fill"
        }
    }
}
