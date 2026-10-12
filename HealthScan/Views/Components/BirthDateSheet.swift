//
//  BirthDateSheet.swift
//  HealthScan
//
//  Modal picker for selecting birth date.
//

import SwiftUI

struct BirthDateSheet: View {
    @Binding var date: Date
    var onDone: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select birth month & year",
                    selection: $date,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                
                Spacer()
            }
            .navigationTitle("Birth date")
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
    BirthDateSheet(date: .constant(Date()), onDone: {})
}
