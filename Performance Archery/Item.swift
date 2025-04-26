//
//  Item.swift
//  Performance Archery
//
//  Created by Luke Myers on 05/01/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    var arrowCount: UInt
    var comeDowns: UInt
    
    init(timestamp: Date) {
        self.timestamp = timestamp
        self.arrowCount = 0
        self.comeDowns = 0
    }
}
