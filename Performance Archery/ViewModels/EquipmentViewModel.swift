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
    
    var setups: [ArcherySetup] = [] {
        didSet { saveSetups() }
    }
    
    var activeSetupId: UUID {
        didSet { UserDefaults.standard.set(activeSetupId.uuidString, forKey: "activeSetupId") }
    }
    
    var sightMarks: [SightMark] {
        get { setups[activeIndex].sightMarks }
        set { setups[activeIndex].sightMarks = newValue }
    }
    
    private var tillerMM: Double = 0
    private var bracingHeightCM: Double = 0
    
    var inputDistance: Double? = nil
    var inputSightValue: Double? = nil
    var inputExtensionValue: Int? = nil
    var showEditSightmarksSheet: Bool = false
    var showAddSetupSheet: Bool = false
    var showEditSetupSheet: Bool = false
    
    init() {
        if let raw = UserDefaults.standard.string(forKey: "unitSystem"),
           let system = UnitSystem(rawValue: raw) {
            self.unitSystem = system
        }
        
        if let data = UserDefaults.standard.data(forKey: "setupsJSON"),
           let decoded = try? JSONDecoder().decode([ArcherySetup].self, from: data), !decoded.isEmpty {
            self.setups = decoded
            
            if let activeString = UserDefaults.standard.string(forKey: "activeSetupId"),
               let activeUUID = UUID(uuidString: activeString),
               decoded.contains(where: { $0.id == activeUUID }) {
                self.activeSetupId = activeUUID
            } else {
                self.activeSetupId = decoded[0].id
            }
        } else {
            let oldTiller = UserDefaults.standard.double(forKey: "tiller_mm")
            let oldBH = UserDefaults.standard.double(forKey: "bracingHeight_cm")
            
            var oldMarks: [SightMark] = []
            if let data = UserDefaults.standard.data(forKey: "sightMarksJSON"),
               let decodedMarks = try? JSONDecoder().decode([SightMark].self, from: data) {
                oldMarks = decodedMarks
            }
            
            let defaultSetup = ArcherySetup(
                id: UUID(),
                name: "Primary Setup",
                description: "My default equipment.",
                tillerMM: oldTiller,
                bracingHeightCM: oldBH,
                sightMarks: oldMarks
            )
            
            self.setups = [defaultSetup]
            self.activeSetupId = defaultSetup.id
        }
    }
    
    private var activeIndex: Int {
        setups.firstIndex(where: { $0.id == activeSetupId }) ?? 0
    }
    
    var tillerDisplay: Double {
        get {
            let tillerMM = setups[activeIndex].tillerMM
            return unitSystem == .metric ? tillerMM : tillerMM / 25.4
        }
        set {
            let tillerMM = unitSystem == .metric ? newValue : newValue * 25.4
            setups[activeIndex].tillerMM = tillerMM
        }
    }
    
    var bracingHeightDisplay: Double {
        get {
            let bracingHeightCM = setups[activeIndex].bracingHeightCM
            return unitSystem == .metric ? bracingHeightCM : bracingHeightCM / 2.54
        }
        set {
            let bracingHeightCM = unitSystem == .metric ? newValue : newValue * 2.54
            setups[activeIndex].bracingHeightCM = bracingHeightCM
        }
    }
    
    var sortedSightMarks: [SightMark] {
        sightMarks.sorted { $0.distanceMeters < $1.distanceMeters }
    }
    
    var canAddSightMark: Bool {
        guard let dist = inputDistance, let sight = inputSightValue else { return false }
        return dist >= 0 && sight >= 0 && sight <= 100
    }
    
    var chartXDomain: ClosedRange<Double> {
        let distances = sightMarks.map { displayDistance($0.distanceMeters) }
        
        guard let minDist = distances.min(), let maxDist = distances.max() else {
            return 0...100
        }
        
        let lowerBound = max(0, minDist - 1)
        let upperBound = (minDist == maxDist) ? (maxDist + 10) : maxDist
        
        return lowerBound...upperBound
    }
    
    func addSightMark() {
        guard let distance = inputDistance, let sightValue = inputSightValue, let extensionValue = inputExtensionValue else { return }
        
        let distanceMeters = unitSystem == .metric ? distance : distance * 0.9144
        let newMark = SightMark(distanceMeters: distanceMeters, sightValue: sightValue, extensionValue: extensionValue)
        
        sightMarks.append(newMark)
        
        inputDistance = nil
        inputSightValue = nil
        inputExtensionValue = nil
    }
    
    func deleteSightMark(id: UUID) {
        sightMarks.removeAll { $0.id == id }
    }
    
    func displayDistance(_ meters: Double) -> Double {
        unitSystem == .metric ? meters : meters / 0.9144
    }
    
    func createNewSetup(name: String, description: AttributedString) {
        let newSetup = ArcherySetup(name: name, description: description)
        setups.append(newSetup)
        activeSetupId = newSetup.id
    }
    
    func updateActiveSetup(name: String, description: AttributedString) {
        let index = activeIndex
        setups[index].name = name
        setups[index].description = description
    }
    
    func deleteActiveSetup() {
        guard setups.count > 1 else { return }
        
        let idToDelete = activeSetupId
        
        if let fallbackSetup = setups.first(where: { $0.id != idToDelete }) {
            activeSetupId = fallbackSetup.id
        }
        
        setups.removeAll { $0.id == idToDelete }
    }
    
    private func saveSetups() {
        if let data = try? JSONEncoder().encode(setups) {
            UserDefaults.standard.set(data, forKey: "setupsJSON")
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
