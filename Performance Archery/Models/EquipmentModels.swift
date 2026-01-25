//
//  EquipmentModels.swift
//  Performance Archery
//
//  Created by Luke Myers on 17/01/2026.
//

import Foundation

enum UnitSystem: String, CaseIterable, Identifiable, Codable {
    case metric
    case imperial
    
    var id: String { rawValue }
    var label: String { self == .metric ? "Metric" : "Imperial" }

    var tillerUnitLabel: String { self == .metric ? "mm" : "in" }
    var bracingHeightUnitLabel: String { self == .metric ? "cm" : "in" }
    var distanceUnitLabel: String { self == .metric ? "m" : "yd" }
}

struct SightMark: Identifiable, Codable, Equatable {
    var id = UUID()
    var distanceMeters: Double
    var sightValue: Double
}
