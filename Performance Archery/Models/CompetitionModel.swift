//
//  CompetitionModel.swift
//  Performance Archery
//
//  Created by Luke Myers on 27/04/2025.
//

import CoreLocation
import Foundation
import SwiftData

@Model
final class Competition {
    @Attribute(.unique) var id: UUID
    
    var name: String
    @Relationship(deleteRule: .cascade) var rounds: [CompetitionRound] = []
    var cost: String
    var arrowCount: UInt
    
    var isEntryReminderSet: Bool
    var entryOpeningTime: Date?
    var startDate: Date
    var endDate: Date
    var latitude: Double?
    var longitude: Double?
    var goals: String
    var reflection: String
    
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
    
    @Relationship(deleteRule: .cascade) var schedule: [ScheduleItem] = []
    
    init(id: UUID = UUID(), isEntryReminderSet: Bool, entryOpeningTime: Date? = nil, startDate: Date, endDate: Date = Date(), multiDay: Bool, name: String, cost: String, arrowCount: UInt = 0, rounds: [CompetitionRound], goals: String, reflection: String, locationName: String, location: CLLocationCoordinate2D?) {
        self.id = id
        
        self.isEntryReminderSet = isEntryReminderSet
        self.entryOpeningTime = entryOpeningTime
        self.startDate = startDate
        
        if multiDay {
            self.endDate = endDate
        } else {
            self.endDate = startDate
        }
        
        self.latitude = location?.latitude
        self.longitude = location?.longitude
        self.goals = goals
        self.reflection = reflection
        
        self.name = name
        self.locationName = locationName
        self.rounds = rounds
        self.cost = cost
        self.arrowCount = arrowCount
        
        self.schedule = []
    }
}

@Model
final class ScheduleItem {
    var title: String
    var dateTime: Date?
    var index: Int
    
    init(title: String, dateTime: Date? = nil, index: Int) {
        self.title = title
        self.dateTime = dateTime
        self.index = index
    }
}

@Model
final class CompetitionRound {
    @Attribute(.unique) var id: UUID
    @Attribute var index: Int
    
    var roundType: RoundType
    var arrowCount: UInt8
    var comeDowns: UInt8
    var startTime: Date?
    var score: String
    var targetAssignment: String

    init(id: UUID = UUID(), index: Int = 0, roundType: RoundType, startTime: Date? = nil, arrowCount: UInt8 = 0, comeDowns: UInt8 = 0, score: String = "", targetAssignment: String = "") {
        self.id = id
        self.index = index
        self.roundType = roundType
        self.arrowCount = arrowCount
        self.comeDowns = comeDowns
        self.startTime = startTime
        self.score = score
        self.targetAssignment = targetAssignment
    }
}

struct RoundType: Hashable, Codable {
    var id: String { name }

    var name: String
    var distances: [UInt8]
    var isMetric: Bool
    var isIndoor: Bool
    var targetFaces: [String]
    var arrowCounts: [UInt8]

    init(name: String, distances: [UInt8], isMetric: Bool, isIndoor: Bool, targetFaces: [String], arrowCounts: [UInt8]) {
        self.name = name
        self.distances = distances
        self.isMetric = isMetric
        self.isIndoor = isIndoor
        self.targetFaces = targetFaces
        self.arrowCounts = arrowCounts
    }
}
