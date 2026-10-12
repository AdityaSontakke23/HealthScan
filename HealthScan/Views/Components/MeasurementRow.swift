//
//  MeasurementRow.swift
//  HealthScan
//
//  List row displaying summary information for a measurement.
//

import SwiftUI

struct MeasurementRow: View {
    let measurement: Measurement
    
    @Environment(\.colorScheme) private var colorScheme
    private let primaryBlue = Color(red: 0.0, green: 0.34, blue: 0.65)
    private let accentOrange = Color(red: 1.0, green: 0.51, blue: 0.0)
    
    var body: some View {
        HStack(spacing: 16) {
            // Heart icon with BPM
            ZStack {
                Circle()
                    .fill((colorScheme == .dark ? Color.white : accentOrange).opacity(0.12))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(accentOrange)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(measurement.bpm)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? Color.white : primaryBlue)
                    
                    Text("BPM")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.7) : primaryBlue.opacity(0.6))
                }
                
                Text(measurement.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.6) : primaryBlue.opacity(0.5))
            }
            
            Spacer()
            
            // Quality indicator
            QualityIndicator(quality: measurement.quality)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle((colorScheme == .dark ? Color.white : primaryBlue).opacity(0.35))
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    let sample = Measurement(
        userId: "test",
        duration: 30,
        sampleRate: 30,
        bpm: 74,
        quality: .good,
        ppgData: []
    )
    MeasurementRow(measurement: sample)
        .padding()
}
