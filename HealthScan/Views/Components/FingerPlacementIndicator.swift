//
//  FingerPlacementIndicator.swift
//  HealthScan
//
//  Visual status indicator showing finger placement on the camera sensor.
//

import SwiftUI

struct FingerPlacementIndicator: View {
    let sampleCount: Int
    let signalQuality: SignalQuality
    var contactState: SensorContactState = .measuring
    
    private var signalStrength: SignalStrength {
        switch contactState {
        case .noFinger:
            return .none
        case .calibrating:
            return .calibrating
        case .measuring:
            return signalQuality == .good ? .good : .weak
        }
    }
    
    enum SignalStrength {
        case none, calibrating, weak, good
        
        var color: Color {
            switch self {
            case .none: return .red
            case .calibrating: return .cyan
            case .weak: return .yellow
            case .good: return Color(red: 1.0, green: 0.51, blue: 0.0)
            }
        }
        
        var text: String {
            switch self {
            case .none: return "Cover camera & flash with finger"
            case .calibrating: return "Calibrating sensor..."
            case .weak: return "Hold steady for clearer signal"
            case .good: return "Signal looks good"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(signalStrength.color)
                .frame(width: 8, height: 8)
            
            Text(signalStrength.text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    FingerPlacementIndicator(sampleCount: 50, signalQuality: .good)
        .padding()
        .background(Color.black)
}
