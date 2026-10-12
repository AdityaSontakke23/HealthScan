//
//  CameraError.swift
//  HealthScan
//
//  Errors encountered during camera capture setup.
//

import Foundation

enum CameraError: LocalizedError, Sendable {
    case cameraUnavailable
    case cannotAddInput
    case cannotAddOutput
    
    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "Back camera is not available"
        case .cannotAddInput:
            return "Cannot add camera input"
        case .cannotAddOutput:
            return "Cannot add video output"
        }
    }
}
