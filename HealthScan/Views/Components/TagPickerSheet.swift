//
//  TagPickerSheet.swift
//  HealthScan
//
//  Bottom sheet prompting the user to tag their measurement context.
//

import SwiftUI

struct TagPickerSheet: View {
    let onSelect: (MeasurementTag?) -> Void
    @Environment(\.dismiss) private var dismiss
    private let primaryBlue = Color(red: 0.0, green: 0.34, blue: 0.65)
    private let accentOrange = Color(red: 1.0, green: 0.51, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What were you doing?")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .padding(.top, 24)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(MeasurementTag.allCases, id: \.self) { tag in
                    Button {
                        onSelect(tag)
                        dismiss()
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: tag.iconName)
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(accentOrange)
                            Text(tag.rawValue)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(primaryBlue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(primaryBlue.opacity(0.07))
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(primaryBlue.opacity(0.12), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Button {
                onSelect(nil)
                dismiss()
            } label: {
                Text("Skip")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(primaryBlue.opacity(0.6))
            }
            .padding(.bottom, 20)
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
    }
}
