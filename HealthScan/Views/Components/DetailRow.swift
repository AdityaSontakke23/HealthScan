//
//  DetailRow.swift
//  HealthScan
//
//  Key-value row used in measurement detail sections.
//

import SwiftUI

struct DetailRow: View {
    let label: String
    let value: String
    
    @Environment(\.colorScheme) private var colorScheme
    private let primaryBlue = Color(red: 0.0, green: 0.34, blue: 0.65)
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.75) : primaryBlue.opacity(0.6))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? Color.white : primaryBlue)
        }
    }
}

#Preview {
    DetailRow(label: "Sample Rate", value: "30.0 Hz")
        .padding()
}
