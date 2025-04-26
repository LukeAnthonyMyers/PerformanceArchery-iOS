//
//  ActivitiesView.swift
//  Performance Archery
//
//  Created by Luke Myers on 05/01/2025.
//

import SwiftUI

struct ActivitiesView: View {
    @State private var originals: Bool = false
    
    let allActivities = [Activities(type: "Single Player", activities: [
                                Activity(name: "Original Gold Game", explanation: "7- = -1, 8 = 0, 9+ =1)", logo: "smallcircle.circle", multiplayer: false, view: GoldGameView(original: true)),
                                Activity(name: "9.5 Gold Game", explanation: "(8- = -1, 9+ = 1)", logo: "smallcircle.circle", multiplayer: false, view: GoldGameView(original: false))]),
                         Activities(type: "Multiplayer", activities: [
                            Activity(name: "Swedish Dot", explanation: "Closest to centre", logo: "target", multiplayer: true, view: SwedishDotView(spots: 3))])]
    
    var body: some View {
        NavigationView {
            List(allActivities) { activityCategory in
                Section(header: Text(activityCategory.type)) {
                    ForEach(activityCategory.activities) { activity in
                        NavigationLink {
                            AnyView(activity.view)
                        } label: {
                            HStack {
                                Label(activity.name, systemImage: activity.logo)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Activities")
        }
    }
}

struct Activities: Identifiable {
    var id = UUID()
    var type: String
    var activities: [Activity] = []
}

#Preview {
    ActivitiesView()
}
