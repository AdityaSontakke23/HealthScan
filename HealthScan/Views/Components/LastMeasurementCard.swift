//
//  LastMeasurementCard.swift
//  HealthScan
//
//  Card showing the most recent heart rate measurement.
//

import SwiftUI

struct LastMeasurementCard: View {
    let measurement: Measurement
    
    @Environment(\.colorScheme) private var colorScheme
    private let primaryBlue = Color(red: 0.0, green: 0.34, blue: 0.65)
    private let accentOrange = Color(red: 1.0, green: 0.51, blue: 0.0)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last Measurement")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.6) : primaryBlue.opacity(0.5))
            
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(accentOrange)
                    Text("\(measurement.bpm)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? Color.white : primaryBlue)
                    Text("BPM")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.7) : primaryBlue.opacity(0.6))
                }
                
                Spacer()
                
                Text(measurement.formattedDate)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.6) : primaryBlue.opacity(0.5))
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : primaryBlue.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 8, y: 4)
    }
}

#Preview {
    let sample = Measurement(
        userId: "preview",
        duration: 30,
        sampleRate: 30,
        bpm: 72,
        quality: .good,
        ppgData: []
    )
    LastMeasurementCard(measurement: sample)
        .padding()
}
