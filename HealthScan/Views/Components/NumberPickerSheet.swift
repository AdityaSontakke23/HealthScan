//
//  NumberPickerSheet.swift
//  HealthScan
//
//  Wheel picker sheet for selecting numeric measurements like height and weight.
//

import SwiftUI

struct NumberPickerSheet: View {
    let title: String
    let range: ClosedRange<Int>
    @Binding var selection: Int
    var onDone: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("", selection: $selection) {
                    ForEach(Array(range), id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .labelsHidden()
                .pickerStyle(.wheel)
                .frame(maxHeight: 250)
                
                Spacer()
            }
            .navigationTitle(title)
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onDone() }
                        .font(.headline)
                }
            }
        }
    }
}

#Preview {
    NumberPickerSheet(title: "Weight (kg)", range: 40...180, selection: .constant(70), onDone: {})
}
