//
//  QualityBadge.swift
//  HealthScan
//
//  Badge showing the assessed quality of a PPG measurement.
//

import SwiftUI

struct QualityBadge: View {
    let quality: SignalQuality
    
    private var backgroundColor: Color {
        quality == .good ? Color.green.opacity(0.15) : Color.orange.opacity(0.15)
    }
    
    private var textColor: Color {
        quality == .good ? .green : .orange
    }
    
    private var icon: String {
        quality == .good ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text("Signal Quality: \(quality.rawValue)")
        }
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .foregroundStyle(textColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .clipShape(Capsule())
    }
}

#Preview {
    QualityBadge(quality: .good)
        .padding()
}
