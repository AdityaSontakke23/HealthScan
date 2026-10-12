//
//  Gender.swift
//  HealthScan
//
//  Gender options for profile demographics.
//

import Foundation

enum Gender: String, CaseIterable, Codable, Sendable {
    case male, female, unspecified
    
    var label: String {
        switch self {
        case .male: return "Man"
        case .female: return "Woman"
        case .unspecified: return "Prefer not to say"
        }
    }
}
