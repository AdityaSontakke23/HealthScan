//
//  MeasurementDetailView.swift
//  HealthScan
//
//  Sheet view displaying detailed measurement information.
//

import SwiftUI

struct MeasurementDetailView: View {
    let measurement: Measurement
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private let primaryBlue = Color(red: 0.0, green: 0.34, blue: 0.65)
    private let darkBlue = Color(red: 0.02, green: 0.16, blue: 0.32)
    private let accentOrange = Color(red: 1.0, green: 0.51, blue: 0.0)
    
    private var backgroundGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color.black, darkBlue.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [primaryBlue.opacity(0.05), primaryBlue.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // BPM display
                    VStack(spacing: 8) {
                        HStack(alignment: .lastTextBaseline, spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(accentOrange)
                            
                            Text("\(measurement.bpm)")
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundStyle(colorScheme == .dark ? Color.white : primaryBlue)
                            
                            Text("BPM")
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.7) : primaryBlue.opacity(0.6))
                        }
                        
                        QualityBadge(quality: measurement.quality)
                        
                        if let hrv = measurement.hrvMs {
                            HStack(spacing: 6) {
                                Image(systemName: "waveform.path.ecg")
                                    .font(.system(size: 14))
                                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.7) : primaryBlue.opacity(0.6))
                                Text(String(format: "%.0f ms HRV", hrv))
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.7) : primaryBlue.opacity(0.6))
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // Detailed Physiological Report & Biomarker Grid
                    HealthReportCard(measurement: measurement)
                    
                    // PPG Plot
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PPG Recording")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(colorScheme == .dark ? Color.white : primaryBlue)
                        
                        StaticPPGPlotView(data: measurement.ppgData)
                            .frame(height: 160)
                    }
                    .padding(.horizontal, 20)
                    
                    // Details
                    VStack(spacing: 12) {
                        if let tag = measurement.tag {
                            DetailRow(label: "Activity State", value: tag.rawValue)
                        }
                        DetailRow(label: "Date", value: measurement.formattedDate)
                        DetailRow(label: "Duration", value: String(format: "%.1f seconds", measurement.duration))
                        if let hrv = measurement.hrvMs {
                            DetailRow(label: "HRV (rMSSD)", value: String(format: "%.0f ms", hrv))
                        }
                        DetailRow(label: "Sample Rate", value: String(format: "%.1f Hz", measurement.sampleRate))
                        DetailRow(label: "Device", value: measurement.deviceModel)
                    }
                    .padding(20)
                    .background(colorScheme == .dark ? Color.white.opacity(0.12) : Color.white)
                    .clipShape(.rect(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.18) : primaryBlue.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 10, y: 6)
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 30)
            }
            .background(backgroundGradient.ignoresSafeArea())
            .navigationTitle("Measurement")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(colorScheme == .dark ? Color.white : primaryBlue)
                }
            }
        }
    }
}

#Preview {
    let sample = Measurement(
        userId: "test",
        duration: 30,
        sampleRate: 30,
        bpm: 72,
        quality: .good,
        ppgData: []
    )
    MeasurementDetailView(measurement: sample)
}
