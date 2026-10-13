//
//  DisclaimerView.swift
//  HealthScan
//
//  First-launch disclaimer modal. Shown once and stored in @AppStorage.
//

import SwiftUI

struct DisclaimerView: View {
    let onAccept: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    private let primaryBlue = Color(red: 0.0, green: 0.34, blue: 0.65)
    private let accentOrange = Color(red: 1.0, green: 0.51, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 64))
                .foregroundStyle(accentOrange)
            
            Text("Welcome to HealthScan")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? .white : primaryBlue)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 16) {
                DisclaimerRow(icon: "camera.fill", text: "Uses your camera and torch to measure heart rate")
                DisclaimerRow(icon: "lock.fill", text: "All data stays on your device — never uploaded")
                DisclaimerRow(icon: "exclamationmark.triangle.fill", text: "Not a medical device. Not for clinical diagnosis or treatment.")
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: onAccept) {
                Text("I Understand — Get Started")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(accentOrange)
                    .clipShape(.rect(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

private struct DisclaimerRow: View {
    let icon: String
    let text: String
    private let primaryBlue = Color(red: 0.0, green: 0.34, blue: 0.65)
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(primaryBlue)
                .frame(width: 28)
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.85) : primaryBlue)
        }
    }
}

#Preview {
    DisclaimerView(onAccept: {})
}
