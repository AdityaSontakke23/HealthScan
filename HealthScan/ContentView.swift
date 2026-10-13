//
//  ContentView.swift
//
//  Main content view - entry point for the app UI.
//

import SwiftUI

struct ContentView: View {
    @State private var measurementStore = MeasurementStore()
    @State private var selectedTab = 1
    @AppStorage("hasAcceptedDisclaimer") private var hasAcceptedDisclaimer = false
    
    var body: some View {
        if !hasAcceptedDisclaimer {
            DisclaimerView {
                hasAcceptedDisclaimer = true
            }
        } else {
            TabView(selection: $selectedTab) {
                Tab("History", systemImage: "clock.arrow.circlepath", value: 0) {
                    NavigationStack {
                        HistoryView()
                    }
                }
                
                Tab("Record", systemImage: "plus.circle.fill", value: 1) {
                    NavigationStack {
                        HomeView()
                    }
                }
                
                Tab("Profile", systemImage: "person.crop.circle", value: 2) {
                    NavigationStack {
                        ProfileView()
                    }
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .environment(measurementStore)
        }
    }
}

#Preview {
    ContentView()
}
