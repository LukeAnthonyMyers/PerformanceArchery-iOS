//
//  ActivitiesView.swift
//  Performance Archery
//
//  Created by Luke Myers on 05/01/2025.
//

import SwiftUI

struct ActivitiesView: View {
    @State private var arrowValue = "0"
    private var games = [Game(id: "Original Gold Game", description: "7- = -1, 8 = 0, 9+ =1)", logo: "target"),
                         Game(id: "9.5 Gold Game", description: "(8- = -1, 9+ = 1)", logo: "target"),
                         Game(id: "Swedish Dot", description: "Closest to centre", logo: "smallcircle.circle")]
    
    var body: some View {
        List(games) { game in
            HStack{
                Label(game.id, systemImage: game.logo)
            }
        }
    }
}

struct Game: Identifiable {
    var id: String
    var description: String
    var logo: String
}

#Preview {
    ActivitiesView()
}
