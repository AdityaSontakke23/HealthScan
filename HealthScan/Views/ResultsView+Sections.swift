//
//  ResultsView+Sections.swift
//  ClimbPulse
//
//  Extracted view sections for ResultsView.
//

import SwiftUI
import UIKit

extension ResultsView {
    
    var successHeaderSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accentOrange.opacity(colorScheme == .dark ? 0.15 : 0.1))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(accentOrange)
            }
            
            Text("Measurement Complete")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(primaryText)
        }
        .padding(.top, 16)
    }
    
    var bpmResultCardSection: some View {
        VStack(spacing: 14) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(accentOrange)
                
                Text("\(measurement.bpm)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)
                    .scaleEffect(bpmScale)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            bpmScale = 1.0
                        }
                        let feedback = UINotificationFeedbackGenerator()
                        feedback.notificationOccurred(.success)
                    }
                
                Text("BPM")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(secondaryText)
            }
            
            QualityBadge(quality: measurement.quality)
            
            if let hrv = measurement.hrvMs {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(secondaryText)
                    Text(String(format: "%.0f ms HRV", hrv))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(secondaryText)
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(cardBorder, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.12), radius: 15, y: 8)
        .padding(.horizontal, 20)
    }
    
    var contextTagSelectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What were you doing?")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(primaryText)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MeasurementTag.allCases, id: \.self) { tag in
                        let isSelected = selectedTag == tag
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTag = tag
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: tag.iconName)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(tag.rawValue)
                                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(isSelected ? .white : primaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(isSelected ? accentOrange : cardBackground)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(isSelected ? accentOrange : cardBorder, lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    var ppgPlotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PPG Recording")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(primaryText)
            
            StaticPPGPlotView(data: measurement.ppgData)
                .frame(height: 160)
        }
        .padding(.horizontal, 20)
    }
    
    var measurementDetailsSection: some View {
        VStack(spacing: 12) {
            DetailRow(label: "Activity State", value: selectedTag.rawValue)
            DetailRow(label: "Duration", value: String(format: "%.1f seconds", measurement.duration))
            if let hrv = measurement.hrvMs {
                DetailRow(label: "HRV (rMSSD)", value: String(format: "%.0f ms", hrv))
            }
            DetailRow(label: "Sample Rate", value: String(format: "%.1f Hz", measurement.sampleRate))
            DetailRow(label: "Recorded", value: measurement.formattedDate)
            DetailRow(label: "Device", value: measurement.deviceModel)
        }
        .padding(20)
        .background(colorScheme == .dark ? Color.white.opacity(0.12) : Color.white)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(colorScheme == .dark ? Color.white.opacity(0.18) : cardBorder, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.25), radius: 10, y: 6)
        .padding(.horizontal, 20)
    }
}
