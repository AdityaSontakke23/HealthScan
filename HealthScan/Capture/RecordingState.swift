//
//  RecordingState.swift
//  HealthScan
//
//  Thread-safe storage for recording timestamps accessed across capture threads.
//

import Foundation
import CoreMedia

/// Thread-safe storage for recording start time (accessed from multiple threads).
nonisolated final class RecordingState: @unchecked Sendable {
    private let lock = NSLock()
    private var _startTime: Date?
    private var _startPTS: CMTime?
    
    var startTime: Date? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _startTime
        }
        set {
            lock.lock()
            _startTime = newValue
            lock.unlock()
        }
    }
    
    var startPTS: CMTime? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _startPTS
        }
        set {
            lock.lock()
            _startPTS = newValue
            lock.unlock()
        }
    }
}
