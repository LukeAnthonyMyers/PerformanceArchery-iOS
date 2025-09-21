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
            CalendarView()
                .tabItem() {
                    Label("Calendar", systemImage: "calendar")
                }
            ActivitiesView()
                .tabItem() {
                    Label("Activities", systemImage: "figure.archery")
                }
            ToolsView()
                .tabItem() {
                    Label("Tools", systemImage: "wrench.and.screwdriver.fill")
                }
            TrainingLogView()
                .tabItem() {
                    Label("Training Log", systemImage: "list.bullet.clipboard")
                }
        }
    }
}

#Preview {
    ContentView()
}
