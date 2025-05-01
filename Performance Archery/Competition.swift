//
//  Competition.swift
//  Performance Archery
//
//  Created by Luke Myers on 27/04/2025.
//

import CoreLocation
import SwiftData

@Model
final class Competition {
    @Attribute(.unique) var id: UUID
    
    var name: String
    var round: String
    var cost: String
    var score: String
    var arrowCount: UInt
    
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
    
    init(id: UUID = UUID(), dateTime: Date, name: String, cost: String, score: String = "0", arrowCount: UInt = 0, round: String, goals: String, reflection: String, location: CLLocationCoordinate2D?) {
        self.id = id
        
        self.dateTime = dateTime
        self.latitude = location?.latitude
        self.longitude = location?.longitude
        self.goals = goals
        self.reflection = reflection
        
        self.name = name
        self.round = round
        self.cost = cost
        self.score = score
        self.arrowCount = arrowCount
    }
}
