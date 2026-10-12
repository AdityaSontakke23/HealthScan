//
//  ProfileView.swift
//  ClimbPulse
//
//  Simple profile form for user demographics.
//

import SwiftUI

struct ProfileView: View {
    @AppStorage("profile_gender") private var gender: Gender = .unspecified
    @AppStorage("profile_birthdate") private var birthDate: Double = Calendar.current.date(byAdding: .year, value: -25, to: Date())?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
    @AppStorage("profile_education") private var education: Education = .unspecified
    @AppStorage("profile_weight") private var weight: String = ""
    @AppStorage("profile_height") private var height: String = ""
    
    @State private var showBirthSheet = false
    @State private var showWeightSheet = false
    @State private var showHeightSheet = false
    @State private var pickerWeight: Int = 65
    @State private var pickerHeight: Int = 170
    
    private var birthDateBinding: Binding<Date> {
        Binding<Date>(
            get: { Date(timeIntervalSince1970: birthDate) },
            set: { birthDate = $0.timeIntervalSince1970 }
        )
    }
    
    var body: some View {
        Form {
            Section("Basic Info") {
                Picker("Legal gender", selection: $gender) {
                    ForEach(Gender.allCases, id: \.self) { g in
                        Text(g.label).tag(g)
                    }
                }
                
                Button {
                    showBirthSheet = true
                } label: {
                    HStack {
                        Text("Birth month & year")
                        Spacer()
                        Text(formattedBirthDate)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Picker("Education", selection: $education) {
                    ForEach(Education.allCases, id: \.self) { e in
                        Text(e.label).tag(e)
                    }
                }
            }
            
            Section("Body Metrics") {
                Button {
                    pickerWeight = Int(weight) ?? 65
                    showWeightSheet = true
                } label: {
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        Text(weight.isEmpty ? "Not set" : weight)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button {
                    pickerHeight = Int(height) ?? 170
                    showHeightSheet = true
                } label: {
                    HStack {
                        Text("Height (cm)")
                        Spacer()
                        Text(height.isEmpty ? "Not set" : height)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showBirthSheet) {
            BirthDateSheet(date: birthDateBinding) { showBirthSheet = false }
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showWeightSheet) {
            NumberPickerSheet(
                title: "Weight (kg)",
                range: 40...180,
                selection: $pickerWeight,
                onDone: {
                    weight = "\(pickerWeight)"
                    showWeightSheet = false
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showHeightSheet) {
            NumberPickerSheet(
                title: "Height (cm)",
                range: 140...220,
                selection: $pickerHeight,
                onDone: {
                    height = "\(pickerHeight)"
                    showHeightSheet = false
                }
            )
            .presentationDetents([.medium, .large])
        }
    }
    
    private var formattedBirthDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: Date(timeIntervalSince1970: birthDate))
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
