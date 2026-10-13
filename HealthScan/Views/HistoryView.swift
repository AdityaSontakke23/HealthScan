//
//  HistoryView.swift
//  ClimbPulse
//
//  History view showing past measurements sorted by date.
//

import SwiftUI
import Charts

struct HistoryView: View {
    @Environment(MeasurementStore.self) private var measurementStore
    @State private var selectedMeasurement: Measurement?
    @State private var showChart = false
    @Environment(\.colorScheme) private var colorScheme
    
    // JYU-inspired palette
    private let primaryBlue = Color(red: 0.0, green: 0.34, blue: 0.65)      // #0056A5
    private let darkBlue = Color(red: 0.02, green: 0.16, blue: 0.32)       // #042948
    
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
    
    private var primaryText: Color {
        colorScheme == .dark ? Color.white : darkBlue
    }
    
    private var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : darkBlue.opacity(0.6)
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
                .ignoresSafeArea()
            
            if measurementStore.measurements.isEmpty {
                ContentUnavailableView(
                    "No Measurements Yet",
                    systemImage: "heart.text.square",
                    description: Text("Your heart rate measurements will appear here")
                )
            } else {
                VStack(spacing: 0) {
                    // Toggle button for chart
                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            showChart.toggle()
                        }
                    } label: {
                        Label(showChart ? "Hide Trend" : "Show Trend", systemImage: showChart ? "chart.line.uptrend.xyaxis.circle.fill" : "chart.line.uptrend.xyaxis.circle")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(primaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(primaryText.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    if showChart {
                        BPMTrendChart(measurements: measurementStore.measurements)
                            .frame(height: 160)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    List {
                        ForEach(groupedMeasurements, id: \.0) { dateString, measurements in
                            Section {
                                ForEach(measurements) { measurement in
                                    Button {
                                        selectedMeasurement = measurement
                                    } label: {
                                        MeasurementRow(measurement: measurement)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete { offsets in
                                    deleteMeasurements(in: measurements, at: offsets)
                                }
                            } header: {
                                Text(dateString)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(secondaryText)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("History")
        .toolbarTitleDisplayMode(.large)
        .toolbar {
            if !measurementStore.measurements.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: clearAllHistory) {
                            Label("Clear All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(primaryText)
                    }
                }
            }
        }
        .sheet(item: $selectedMeasurement) { measurement in
            MeasurementDetailView(measurement: measurement)
        }
    }
    
    /// Group measurements by date.
    private var groupedMeasurements: [(String, [Measurement])] {
        let grouped = Dictionary(grouping: measurementStore.measurements) { measurement -> String in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: measurement.timestamp)
        }
        
        return grouped.sorted { first, second in
            guard let date1 = first.value.first?.timestamp,
                  let date2 = second.value.first?.timestamp else { return false }
            return date1 > date2
        }
    }
    
    private func deleteMeasurements(in measurements: [Measurement], at offsets: IndexSet) {
        for index in offsets {
            let measurementToDelete = measurements[index]
            measurementStore.delete(measurementToDelete)
        }
    }
    
    private func clearAllHistory() {
        measurementStore.clearAll()
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .environment(MeasurementStore())
    }
}
