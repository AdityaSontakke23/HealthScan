//
//  BPMTrendChart.swift
//  HealthScan
//
//  Swift Charts line chart showing BPM trend over recent measurements.
//

import SwiftUI
import Charts

struct BPMTrendChart: View {
    let measurements: [Measurement]
    @Environment(\.colorScheme) private var colorScheme
    private let accentOrange = Color(red: 1.0, green: 0.51, blue: 0.0)
    private let primaryBlue = Color(red: 0.0, green: 0.34, blue: 0.65)
    
    // Use only the last 20 good-quality measurements for the chart
    private var chartData: [Measurement] {
        measurements.filter { $0.quality == .good }.suffix(20).reversed()
    }
    
    var body: some View {
        if chartData.isEmpty {
            ContentUnavailableView("No Good Readings Yet", systemImage: "chart.line.uptrend.xyaxis")
                .frame(height: 160)
        } else {
            Chart {
                ForEach(Array(chartData.enumerated()), id: \.element.id) { index, m in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("BPM", m.bpm)
                    )
                    .foregroundStyle(accentOrange)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Time", index),
                        yStart: .value("Min", 40),
                        yEnd: .value("BPM", m.bpm)
                    )
                    .foregroundStyle(accentOrange.opacity(0.12))
                    .interpolationMethod(.catmullRom)
                }
                
                // Normal range reference lines
                RuleMark(y: .value("Normal Low", 60))
                    .foregroundStyle(Color.green.opacity(0.4))
                    .lineStyle(StrokeStyle(dash: [4]))
                
                RuleMark(y: .value("Normal High", 100))
                    .foregroundStyle(Color.red.opacity(0.4))
                    .lineStyle(StrokeStyle(dash: [4]))
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(values: [40, 60, 80, 100, 120]) { value in
                    AxisValueLabel {
                        if let bpm = value.as(Int.self) {
                            Text("\(bpm)")
                                .font(.system(size: 11, design: .rounded))
                        }
                    }
                    AxisGridLine()
                }
            }
            .padding(12)
            .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(primaryBlue.opacity(0.08), lineWidth: 1)
            )
        }
    }
}
