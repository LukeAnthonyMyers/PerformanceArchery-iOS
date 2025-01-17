//
//  Activity.swift
//  Performance Archery
//
//  Created by Luke Myers on 08/01/2025.
//

import Foundation
import SwiftUI
import SwiftData

struct Activity: Identifiable {
    var id = UUID()
    var name: String
    var explanation: String
    var logo: String
    var multiplayer: Bool
    var view: any View
    
    init(name: String, explanation: String, logo: String, multiplayer: Bool, view: any View) {
        self.name = name
        self.explanation = explanation
        self.logo = logo
        self.multiplayer = multiplayer
        self.view = view
    }
}
