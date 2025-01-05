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
                    Image(systemName: "calendar")
                    Text("Event Calendar")
                }
            TrainingLogView()
                .tabItem() {
                    Image(systemName: "list.bullet")
                    Text("Training Log")
                }
        }
    }
}

#Preview {
    ContentView()
}
