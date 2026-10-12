//
//  ResultsView.swift
//  ClimbPulse
//
//  Results screen showing final BPM, quality assessment, and PPG plot.
//

import SwiftUI

struct ResultsView: View {
    let measurement: Measurement
    let onDismiss: () -> Void
    
    @Environment(MeasurementStore.self) var measurementStore
    @State var isSaved = false
    @Environment(\.colorScheme) var colorScheme
    
    // JYU-inspired palette
    let primaryBlue = Color(red: 0.0, green: 0.34, blue: 0.65)      // #0056A5
    let darkBlue = Color(red: 0.02, green: 0.16, blue: 0.32)       // #042948
    let accentOrange = Color(red: 1.0, green: 0.51, blue: 0.0)     // #FF8200
    
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
                    VStack(spacing: 32) {
                        successHeaderSection
                        bpmResultCardSection
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
        }
    }
    
    func saveAndDismiss() {
        measurementStore.save(measurement)
        withAnimation {
            isSaved = true
        }
    }
    
    private func createShareText() -> String {
        """
        ClimbPulse Heart Rate Measurement
        ❤️ \(measurement.bpm) BPM
        📊 Quality: \(measurement.quality.rawValue)
        📅 \(measurement.formattedDate)
        """
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
