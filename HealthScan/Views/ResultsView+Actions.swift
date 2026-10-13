//
//  ResultsView+Actions.swift
//  HealthScan
//
//  Action buttons section for ResultsView.
//

import SwiftUI

extension ResultsView {
    
    var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if measurement.quality == .noisy && !isSaved {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
                    Text("Signal was noisy — result may be inaccurate")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(primaryText)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(colorScheme == .dark ? 0.15 : 0.1))
                .clipShape(.rect(cornerRadius: 10))
                
                Button(action: onDismiss) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Retake Measurement")
                    }
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(accentOrange)
                    .clipShape(.rect(cornerRadius: 14))
                }
                
                Button(action: saveAndDismiss) {
                    HStack(spacing: 8) {
                        Image(systemName: isSaved ? "checkmark" : "square.and.arrow.down")
                        Text(isSaved ? "Saved" : "Save Anyway")
                    }
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(primaryText.opacity(colorScheme == .dark ? 0.12 : 0.1))
                    .clipShape(.rect(cornerRadius: 14))
                }
                .disabled(isSaved)
            } else {
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
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
}
