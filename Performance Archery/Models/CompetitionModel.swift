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
class CompetitionStage {
    var dayIndex: UInt
    var sortIndex: Int = 0
    var arrowCount: UInt = 0
    
    init(dayIndex: UInt = 0) {
        self.dayIndex = dayIndex
    }
}

enum RoundDiscipline: Codable {
    case clout
    case field
    case target
}

@Model
final class Competition {
    @Attribute(.unique) var id: UUID
    
    @Relationship(deleteRule: .cascade) var stages: [CompetitionStage] = []
    
    var name: String
    var cost: String
    var arrowCount: UInt
    var isConfirmed: Bool
    var isEntryReminderSet: Bool
    var entryOpeningTime: Date?
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
    
    @Relationship(deleteRule: .cascade) var schedule: [ScheduleItem] = []
    
    init(id: UUID = UUID(), isConfirmed: Bool, isEntryReminderSet: Bool, entryOpeningTime: Date? = nil, startDate: Date, endDate: Date = Date(), multiDay: Bool, name: String, cost: String, arrowCount: UInt = 0, stages: [CompetitionStage], notes: AttributedString, locationName: String, location: CLLocationCoordinate2D?) {
        self.id = id
        
        self.isConfirmed = isConfirmed
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
        self.notes = notes
        
        self.name = name
        self.locationName = locationName
        self.stages = stages
        self.cost = cost
        self.arrowCount = arrowCount
        
        self.schedule = []
    }
}

@Model
final class ScheduleItem {
    var title: String
    var dateTime: Date
    var index: Int
    
    init(title: String, dateTime: Date, index: Int) {
        self.title = title
        self.dateTime = dateTime
        self.index = index
    }
}

@available(iOS 26, *)
@Model
final class CompetitionRound: CompetitionStage {
    @Attribute(.unique) var id: UUID
    
    var roundType: RoundType
    var comeDowns: UInt8?
    var startTime: Date?
    var score: String
    var targetAssignment: String

    init(id: UUID = UUID(), dayIndex: UInt = 0, roundType: RoundType, startTime: Date? = nil, arrowCount: UInt8 = 0, comeDowns: UInt8? = 0, score: String = "", targetAssignment: String = "") {
        self.id = id
        self.roundType = roundType
        self.comeDowns = comeDowns
        self.startTime = startTime
        self.score = score
        self.targetAssignment = targetAssignment
        
        super.init(dayIndex: dayIndex)
    }
}

struct RoundType: Hashable, Codable {
    var id: String { name }

    var name: String
    var distances: [UInt8]
    var isMetric: Bool
    var discipline: RoundDiscipline
    var targetFaces: [String]
    var arrowCounts: [UInt8]

    init(name: String, distances: [UInt8], isMetric: Bool, discipline: RoundDiscipline, targetFaces: [String], arrowCounts: [UInt8]) {
        self.name = name
        self.distances = distances
        self.isMetric = isMetric
        self.discipline = discipline
        self.targetFaces = targetFaces
        self.arrowCounts = arrowCounts
    }
}

@available(iOS 26, *)
@Model
final class HeadToHeadMatch: CompetitionStage {
    var opponentName: String = ""
    var opponentShootOff: Int? = nil    
    var opponentArrows: [[Int]] = [[], [], [], [], []]
    
    var userArrows: [[Int]] = [[], [], [], [], []]
    var userShootOff: Int? = nil
    var userClosestToCenter: Bool = false
    
    init(dayIndex: UInt = 0, opponentName: String = "") {
        self.opponentName = opponentName
        
        super.init(dayIndex: dayIndex)
    }
}
