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
    
    private var signalStrength: SignalStrength {
        if sampleCount < 10 {
            return .none
        } else if signalQuality == .good {
            return .good
        } else {
            return .weak
        }
    }
    
    enum SignalStrength {
        case none, weak, good
        
        var color: Color {
            switch self {
            case .none: return .gray
            case .weak: return .yellow
            case .good: return Color(red: 1.0, green: 0.51, blue: 0.0)
            }
        }
        
        var text: String {
            switch self {
            case .none: return "No signal"
            case .weak: return "Adjust finger for a clearer signal"
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
