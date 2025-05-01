//
//  TrainingSession.swift
//  Performance Archery
//
//  Created by Luke Myers on 05/01/2025.
//

import CoreLocation
import SwiftData

@Model
final class TrainingSession {
    @Attribute(.unique) var id: UUID
    
    var arrowCount: UInt
    var comeDowns: UInt
    
    var dateTime: Date
    var latitude: Double?
    var longitude: Double?
    var goals: String
    var reflection: String
    
    var location: CLLocationCoordinate2D? {
        get {
            guard let lat = latitude, let lon = longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        set {
            latitude = newValue?.latitude
            longitude = newValue?.longitude
        }
    }
    
    init(id: UUID = UUID(), dateTime: Date, goals: String, reflection: String, location: CLLocationCoordinate2D?, arrowCount: UInt = 0, comeDowns: UInt = 0) {
        self.id = id
        
        self.arrowCount = arrowCount
        self.comeDowns = comeDowns
        
        self.dateTime = dateTime
        self.latitude = location?.latitude
        self.longitude = location?.longitude
        self.goals = goals
        self.reflection = reflection
    }
}
