//
//  ShootingSession.swift
//  Performance Archery
//
//  Created by Luke Myers on 05/01/2025.
//

import CoreLocation
import SwiftData

@Model
final class ShootingSession: Hashable {
    @Attribute(.unique) var id: UUID
    
    var dateTime: Date
    var latitude: Double?
    var longitude: Double?
    var goals: String
    var reflection: String
    
    var fixedDistanceShooting: [FixedDistanceShooting] = []
    var CompetitionRounds: [CompetitionRound] = []
    
    var arrowCount: UInt {
        fixedDistanceShooting.reduce(0) { acc, fd in
            acc + fd.arrowCount
        }
    }
    
    var locationName: String
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
    
    init(id: UUID = UUID(), dateTime: Date, goals: String, reflection: String, locationName: String, location: CLLocationCoordinate2D?) {
        self.id = id
        
        self.locationName = locationName
        self.dateTime = dateTime
        self.latitude = location?.latitude
        self.longitude = location?.longitude
        self.goals = goals
        self.reflection = reflection
    }
}

@Model
final class FixedDistanceShooting: Hashable {
    @Attribute(.unique) var id: UUID

    var distance: UInt8
    var metric: Bool
    var targetFace: String
    var arrowCount: UInt
    var comeDowns: UInt
    
    var startTime: Date
    var endTime: Date

    init(id: UUID = UUID(), distance: UInt8, metric: Bool, targetFace: String, startTime: Date, endTime: Date = Date(), arrowCount: UInt = 0, comeDowns: UInt = 0) {
        self.id = id
        self.distance = distance
        self.metric = metric
        self.targetFace = targetFace
        self.arrowCount = arrowCount
        self.comeDowns = comeDowns
        
        self.startTime = startTime
        self.endTime = endTime
    }
}
