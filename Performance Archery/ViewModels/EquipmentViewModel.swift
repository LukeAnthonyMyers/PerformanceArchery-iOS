//
//  EquipmentViewModel.swift
//  Performance Archery
//
//  Created by Luke Myers on 17/01/2026.
//


import SwiftUI

@Observable
class EquipmentViewModel {
    var unitSystem: UnitSystem = .metric {
        didSet {
            UserDefaults.standard.set(unitSystem.rawValue, forKey: "unitSystem")
            convertInputDistanceOnUnitChange(oldValue: oldValue)
        }
    }
    
    var sightMarks: [SightMark] = [] {
        didSet { saveSightMarks() }
    }
    
    private var tillerMM: Double = 0
    private var bracingHeightCM: Double = 0
    
    var inputDistance: Double? = nil
    var inputSightValue: Double? = nil
    var showEditSightmarksSheet: Bool = false
    
    init() {
        if let raw = UserDefaults.standard.string(forKey: "unitSystem"),
           let system = UnitSystem(rawValue: raw) {
            self.unitSystem = system
        }
        
        if let data = UserDefaults.standard.data(forKey: "sightMarksJSON"),
           let decoded = try? JSONDecoder().decode([SightMark].self, from: data) {
            self.sightMarks = decoded
        }
        
        self.tillerMM = UserDefaults.standard.double(forKey: "tiller_mm")
        self.bracingHeightCM = UserDefaults.standard.double(forKey: "bracingHeight_cm")
    }
    
    var tillerDisplay: Double {
        get { unitSystem == .metric ? tillerMM : tillerMM / 25.4 }
        set {
            tillerMM = unitSystem == .metric ? newValue : newValue * 25.4
            UserDefaults.standard.set(tillerMM, forKey: "tiller_mm")
        }
    }
    
    var bracingHeightDisplay: Double {
        get { unitSystem == .metric ? bracingHeightCM : bracingHeightCM / 2.54 }
        set {
            bracingHeightCM = unitSystem == .metric ? newValue : newValue * 2.54
            UserDefaults.standard.set(bracingHeightCM, forKey: "bracingHeight_cm")
        }
    }
    
    var sortedSightMarks: [SightMark] {
        sightMarks.sorted { $0.distanceMeters < $1.distanceMeters }
    }
    
    var canAddSightMark: Bool {
        guard let dist = inputDistance, let sight = inputSightValue else { return false }
        return dist >= 0 && sight >= 0 && sight <= 100
    }
    
    func addSightMark() {
        guard let dist = inputDistance, let sight = inputSightValue else { return }
        
        let distanceMeters = unitSystem == .metric ? dist : dist * 0.9144
        let newMark = SightMark(distanceMeters: distanceMeters, sightValue: sight)
        
        sightMarks.append(newMark)
        
        inputDistance = nil
        inputSightValue = nil
    }
    
    func deleteSightMark(id: UUID) {
        sightMarks.removeAll { $0.id == id }
    }
    
    func displayDistance(_ meters: Double) -> Double {
        unitSystem == .metric ? meters : meters / 0.9144
    }
    
    private func saveSightMarks() {
        if let data = try? JSONEncoder().encode(sightMarks) {
            UserDefaults.standard.set(data, forKey: "sightMarksJSON")
        }
    }
    
    private func convertInputDistanceOnUnitChange(oldValue: UnitSystem) {
        guard let dist = inputDistance else { return }
        
        if oldValue == .metric && unitSystem == .imperial {
            inputDistance = dist / 0.9144
        } else if oldValue == .imperial && unitSystem == .metric {
            inputDistance = dist * 0.9144
        }
    }
}
