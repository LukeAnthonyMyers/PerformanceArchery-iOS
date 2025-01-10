//
//  EventCalendarView.swift
//  Performance Archery
//
//  Created by Luke Myers on 05/01/2025.
//

import SwiftUI

struct EventCalendarView: View {
    var body: some View {
        ZStack {
            Color.blue
            
            Label("Work in progress", systemImage: "calendar")
                    .foregroundColor(Color.white)
                    .font(.system(size: 20))
        }
    }
}

#Preview {
    EventCalendarView()
}
