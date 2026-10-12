//
//  QualityIndicator.swift
//  HealthScan
//
//  Compact pill badge displaying signal quality.
//

import SwiftUI

struct QualityIndicator: View {
    let quality: SignalQuality
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Text(quality.rawValue)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(quality == .good ? .green : .orange)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                (quality == .good ? Color.green : Color.orange).opacity(colorScheme == .dark ? 0.18 : 0.12)
            )
            .clipShape(Capsule())
    }
}

#Preview {
    QualityIndicator(quality: .good)
        .padding()
}
