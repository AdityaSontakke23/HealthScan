//
//  InstructionRow.swift
//  HealthScan
//
//  Row view showing a single setup instruction.
//

import SwiftUI

struct InstructionRow: View {
    let icon: String
    let text: String
    
    @Environment(\.colorScheme) private var colorScheme
    private let primaryBlue = Color(red: 0.0, green: 0.34, blue: 0.65)
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.8) : primaryBlue.opacity(0.7))
                .frame(width: 32)
            
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.85) : primaryBlue.opacity(0.85))
            
            Spacer()
        }
    }
}

#Preview {
    InstructionRow(icon: "timer", text: "Hold still for 30 seconds")
        .padding()
}
