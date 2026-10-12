//
//  Education.swift
//  HealthScan
//
//  Education level options for profile demographics.
//

import Foundation

enum Education: String, CaseIterable, Codable, Sendable {
    case basic, highSchool, university, unspecified
    
    var label: String {
        switch self {
        case .basic: return "Basic"
        case .highSchool: return "High school"
        case .university: return "University"
        case .unspecified: return "Prefer not to say"
        }
    }
}
