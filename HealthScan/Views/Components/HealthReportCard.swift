//
//  HealthReportCard.swift
//  HealthScan
//
//  Displays a detailed multi-section physiological report and biomarker grid.
//

import SwiftUI

struct HealthReportCard: View {
    let measurement: Measurement
    @Environment(\.colorScheme) private var colorScheme
    
    private let primaryBlue = Color(red: 0.0, green: 0.34, blue: 0.65)
    private let accentOrange = Color(red: 1.0, green: 0.51, blue: 0.0)
    
    private var report: HealthReport { HealthReportGenerator.generate(for: measurement) }
    
    private var statusColor: Color {
        switch report.statusColorName {
        case "green": return .green
        case "red": return .red
        default: return accentOrange
        }
    }
    
    private var primaryText: Color { colorScheme == .dark ? .white : primaryBlue }
    private var secondaryText: Color { colorScheme == .dark ? Color.white.opacity(0.78) : primaryBlue.opacity(0.75) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                BiomarkerTile(icon: "waveform.path.ecg", title: "HRV (rMSSD)", value: measurement.hrvMs.map { "\(Int(round($0))) ms" } ?? "--")
                BiomarkerTile(icon: "brain.head.profile", title: "Stress Score", value: measurement.stressScore.map { "\($0)/100" } ?? "--")
                BiomarkerTile(icon: "lungs.fill", title: "Respiratory Rate", value: measurement.respiratoryRate.map { "\($0) brpm" } ?? "--")
                BiomarkerTile(icon: "bolt.heart.fill", title: "Readiness", value: measurement.readinessScore.map { "\($0)%" } ?? "--")
            }
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Circle().fill(statusColor).frame(width: 10, height: 10)
                    Text("PHYSIOLOGICAL ASSESSMENT REPORT")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(secondaryText)
                        .tracking(0.8)
                }
                
                Text(report.headline)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)
                
                Text(report.executiveSummary)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                
                Divider()
                
                ReportSectionView(icon: "heart.text.square.fill", title: "Cardiovascular Status", text: report.cardiovascularAnalysis, primaryText: primaryText, secondaryText: secondaryText, accent: accentOrange)
                ReportSectionView(icon: "waveform.path.ecg.rectangle.fill", title: "Autonomic Nervous System & Stress", text: report.autonomicStressAnalysis, primaryText: primaryText, secondaryText: secondaryText, accent: accentOrange)
                ReportSectionView(icon: "wind", title: "Respiratory Modulation", text: report.respiratoryAnalysis, primaryText: primaryText, secondaryText: secondaryText, accent: accentOrange)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Label("Personalized Recommendations", systemImage: "sparkles")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(primaryText)
                    
                    ForEach(report.recommendations, id: \.self) { rec in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(statusColor)
                                .padding(.top, 2)
                            Text(rec)
                                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                                .foregroundStyle(secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(20)
            .background(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white)
            .clipShape(.rect(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(colorScheme == .dark ? Color.white.opacity(0.14) : primaryBlue.opacity(0.1), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.15), radius: 12, y: 6)
        }
        .padding(.horizontal, 20)
    }
}

private struct BiomarkerTile: View {
    let icon: String
    let title: String
    let value: String
    @Environment(\.colorScheme) private var colorScheme
    private let primaryBlue = Color(red: 0.0, green: 0.34, blue: 0.65)
    private let accentOrange = Color(red: 1.0, green: 0.51, blue: 0.0)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundStyle(accentOrange)
                Text(title).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.7) : primaryBlue.opacity(0.65))
            }
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(colorScheme == .dark ? .white : primaryBlue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(colorScheme == .dark ? Color.white.opacity(0.12) : primaryBlue.opacity(0.08), lineWidth: 1))
    }
}

private struct ReportSectionView: View {
    let icon: String
    let title: String
    let text: String
    let primaryText: Color
    let secondaryText: Color
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13)).foregroundStyle(accent)
                Text(title).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(primaryText)
            }
            Text(text).font(.system(size: 13.5, weight: .regular, design: .rounded)).foregroundStyle(secondaryText).fixedSize(horizontal: false, vertical: true)
        }
    }
}
