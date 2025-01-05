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
            
            Button(action: {
                
            }) {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(Color.white)
                    .font(.system(size: 100))
            }
        }
    }
}

#Preview {
    EventCalendarView()
}
