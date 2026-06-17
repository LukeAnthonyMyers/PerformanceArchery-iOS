//
//  CoachingSession.swift
//  Performance Archery
//
//  Created by Luke Myers on 27/04/2025.
//

import CoreLocation
import SwiftData

@Model
final class CoachingSession {
    @Attribute(.unique) var id: UUID
    
    var coachName: String
    var arrowCount: UInt
    
    var startDate: Date
    var endDate: Date
    
    var latitude: Double?
    var longitude: Double?
    var notes: AttributedString
    
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
    
    init(id: UUID = UUID(), startDate: Date, endDate: Date = Date(), multiDay: Bool, arrowCount: UInt = 0, coachName: String, notes: AttributedString, locationName: String, location: CLLocationCoordinate2D?) {
        self.id = id
        
        self.arrowCount = arrowCount
        self.coachName = coachName
        
        self.startDate = startDate
        
        if multiDay {
            self.endDate = endDate
        } else {
            self.endDate = startDate
        }
        
        self.locationName = locationName
        self.latitude = location?.latitude
        self.longitude = location?.longitude
        self.notes = notes
    }
}
