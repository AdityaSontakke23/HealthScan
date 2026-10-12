//
//  ResultsView+Sections.swift
//  ClimbPulse
//
//  Extracted view sections for ResultsView.
//

import SwiftUI

extension ResultsView {
    
    var successHeaderSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentOrange.opacity(colorScheme == .dark ? 0.15 : 0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(accentOrange)
            }
            
            Text("Measurement Complete")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(primaryText)
        }
        .padding(.top, 20)
    }
    
    var bpmResultCardSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(accentOrange)
                
                Text("\(measurement.bpm)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)
                
                Text("BPM")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(secondaryText)
            }
            
            QualityBadge(quality: measurement.quality)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 15, y: 8)
        .padding(.horizontal, 20)
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
            DetailRow(label: "Duration", value: String(format: "%.1f seconds", measurement.duration))
            DetailRow(label: "Sample Rate", value: String(format: "%.1f Hz", measurement.sampleRate))
            DetailRow(label: "Recorded", value: measurement.formattedDate)
            DetailRow(label: "Device", value: measurement.deviceModel)
        }
        .padding(20)
        .background(
            colorScheme == .dark
            ? Color.white.opacity(0.12)
            : Color.white
        )
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.18) : cardBorder,
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.25), radius: 10, y: 6)
        .padding(.horizontal, 20)
    }
    
    var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: saveAndDismiss) {
                HStack(spacing: 8) {
                    Image(systemName: isSaved ? "checkmark" : "square.and.arrow.down")
                    Text(isSaved ? "Saved" : "Save Result")
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSaved ? Color.green : accentOrange)
                .clipShape(.rect(cornerRadius: 14))
            }
            .disabled(isSaved)
            
            Button(action: onDismiss) {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(primaryText.opacity(colorScheme == .dark ? 0.12 : 0.1))
                    .clipShape(.rect(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
}
