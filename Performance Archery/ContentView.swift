//
//  ContentView.swift
//  Performance Archery
//
//  Created by Luke Myers on 05/01/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            EventCalendarView()
                .tabItem() {
                    Label("Event Calendar", systemImage: "calendar")
                }
            ActivitiesView()
                .tabItem() {
                    Label("Activities", systemImage: "figure.archery")
                }
            TrainingLogView()
                .tabItem() {
                    Label("Training Log", systemImage: "list.bullet")
                }
        }
    }
}

#Preview {
    ContentView()
}
