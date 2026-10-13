//
//  ResultsView.swift
//  ClimbPulse
//
//  Results screen showing final BPM, quality assessment, context tag selector, report, and PPG plot.
//

import SwiftUI
import UIKit

struct ResultsView: View {
    let measurement: Measurement
    let onDismiss: () -> Void
    
    @Environment(MeasurementStore.self) var measurementStore
    @State var isSaved = false
    @State var bpmScale: Double = 0.7
    @State var showTagPicker = false
    @State var selectedTag: MeasurementTag = .resting
    @State var healthKitExported = false
    @Environment(\.colorScheme) var colorScheme
    
    // JYU-inspired palette
    let primaryBlue = Color(red: 0.0, green: 0.34, blue: 0.65)      // #0056A5
    let darkBlue = Color(red: 0.02, green: 0.16, blue: 0.32)       // #042948
    let accentOrange = Color(red: 1.0, green: 0.51, blue: 0.0)     // #FF8200
    
    var activeMeasurement: Measurement {
        Measurement(
            userId: measurement.userId,
            timestamp: measurement.timestamp,
            duration: measurement.duration,
            sampleRate: measurement.sampleRate,
            bpm: measurement.bpm,
            quality: measurement.quality,
            ppgData: measurement.ppgData,
            hrvMs: measurement.hrvMs,
            tag: selectedTag,
            stressScore: measurement.stressScore,
            respiratoryRate: measurement.respiratoryRate,
            readinessScore: measurement.readinessScore
        )
    }
    
    var backgroundGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color.black, darkBlue.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [primaryBlue.opacity(0.02), primaryBlue.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    var cardBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white
    }
    
    var cardBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : primaryBlue.opacity(0.08)
    }
    
    var primaryText: Color {
        colorScheme == .dark ? Color.white : primaryBlue
    }
    
    var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : primaryBlue.opacity(0.6)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        successHeaderSection
                        bpmResultCardSection
                        contextTagSelectorSection
                        HealthReportCard(measurement: activeMeasurement)
                        ppgPlotSection
                        measurementDetailsSection
                        actionButtonsSection
                    }
                }
            }
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: createShareText()) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(primaryText)
                    }
                }
            }
            .onAppear {
                if let existingTag = measurement.tag {
                    selectedTag = existingTag
                }
            }
        }
    }
    
    func saveAndDismiss() {
        let tagged = activeMeasurement
        measurementStore.save(tagged)
        Task {
            _ = await HealthKitManager.shared.requestAuthorization()
            await HealthKitManager.shared.export(tagged)
        }
        withAnimation { isSaved = true }
    }
    
    private func createShareText() -> String {
        let current = activeMeasurement
        let report = HealthReportGenerator.generate(for: current)
        var text = """
        HealthScan Physiological Report
        State: \(selectedTag.rawValue)
        Heart Rate: \(current.bpm) BPM
        """
        if let hrv = current.hrvMs { text += "\nHRV (rMSSD): \(Int(hrv)) ms" }
        if let stress = current.stressScore { text += "\nStress Score: \(stress)/100" }
        if let resp = current.respiratoryRate { text += "\nRespiratory Rate: \(resp) brpm" }
        if let ready = current.readinessScore { text += "\nReadiness: \(ready)%" }
        text += "\n\nSummary: \(report.headline)\n\(report.executiveSummary)"
        return text
    }
}

#Preview {
    let sampleMeasurement = Measurement(
        userId: "test-user",
        duration: 30.0,
        sampleRate: 30.0,
        bpm: 72,
        quality: .good,
        ppgData: (0..<100).map { i in
            120 + 15 * sin(Double(i) / 100.0 * 30.0 * 2 * .pi * 1.2)
        }
    )
    
    ResultsView(measurement: sampleMeasurement, onDismiss: {})
        .environment(MeasurementStore())
}
