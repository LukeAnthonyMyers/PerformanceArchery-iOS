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

struct ArrowScore: Codable, Hashable {
    var value: UInt8
    var isX: Bool
    var xCoordinate: Double?
    var yCoordinate: Double?
    
    var displayText: String {
        if isX { return "X" }
        if value == 0 { return "M" }
        return String(value)
    }
    
    init(value: UInt8, isX: Bool = false, x: Double? = nil, y: Double? = nil) {
        self.value = value
        self.isX = isX
        self.xCoordinate = x
        self.yCoordinate = y
    }
}

@available(iOS 26, *)
@Model
final class CompetitionRound: CompetitionStage {
    @Attribute(.unique) var id: UUID
    
    var roundType: RoundType
    var isDoubleRound: Bool
    
    var comeDowns: UInt8?
    var startTime: Date?
    var targetAssignment: String
    
    var arrows: [ArrowScore] = []
    
    var score: UInt16 {
        return arrows.reduce(0) { $0 + UInt16($1.value) }
    }

    init(id: UUID = UUID(), dayIndex: UInt = 0, roundType: RoundType, isDoubleRound: Bool = false, startTime: Date? = nil, arrowCount: UInt8 = 0, comeDowns: UInt8? = 0, targetAssignment: String = "", arrows: [ArrowScore] = []) {
        self.id = id
        self.roundType = roundType
        self.isDoubleRound = isDoubleRound
        self.comeDowns = comeDowns
        self.startTime = startTime
        self.arrows = arrows
        self.targetAssignment = targetAssignment
        
        super.init(dayIndex: dayIndex)
    }
}

struct FlightEnd: Codable, Hashable {
    var distance: Double
    var bowCategory: String
    
    init(distance: Double, bowCategory: String) {
        self.distance = distance
        self.bowCategory = bowCategory
    }
}

@available(iOS 26, *)
@Model
final class FlightRound: CompetitionStage {
    @Attribute(.unique) var id: UUID
    var startTime: Date?
    
    var ends: [FlightEnd] = []
    
    var endsGroupedByBowCategory: [String: [FlightEnd]] {
        Dictionary(grouping: ends, by: \.bowCategory)
    }
    
    var bestDistances: [String: Double] {
        endsGroupedByBowCategory.mapValues { end in
            end.map(\.distance).max() ?? 0
        }
    }

    init(id: UUID = UUID(), dayIndex: UInt = 0, startTime: Date? = nil, ends: [FlightEnd] = []) {
        self.id = id
        self.startTime = startTime
        self.ends = ends
        
        super.init(dayIndex: dayIndex)
    }
}

struct RoundType: Codable, Hashable {
    var name: String
    
    var distances: [UInt8]
    var isDistanceMetric: Bool
    
    var discipline: RoundDiscipline
    
    var targetSizes: [UInt8]
    var isTargetSizeMetric: [Bool]
    var targetFaces: [TargetFace]
    
    var arrowCounts: [UInt8]
    var arrowsPerEnd: UInt8
    
    var splitScorecards: Bool
    
    init(name: String, distances: [UInt8], isDistanceMetric: Bool, discipline: RoundDiscipline, targetSizes: [UInt8], isTargetSizeMetric: [Bool], targetFaces: [TargetFace], arrowCounts: [UInt8], arrowsPerEnd: UInt8, splitScorecards: Bool = false) {
        self.name = name
        self.distances = distances
        self.isDistanceMetric = isDistanceMetric
        self.discipline = discipline
        self.targetSizes = targetSizes
        self.isTargetSizeMetric = isTargetSizeMetric
        self.targetFaces = targetFaces
        self.arrowCounts = arrowCounts
        self.arrowsPerEnd = arrowsPerEnd
        self.splitScorecards = splitScorecards
    }
}

struct EliminationType: Codable, Hashable {
    var name: String
    var format: MatchFormat
    var isCumulativeScoring: Bool
    
    var distances: [UInt8]
    var isDistanceMetric: Bool
    
    var targetSizes: [UInt8]
    var isTargetSizeMetric: [Bool]
    var targetFaces: [TargetFace]
}

enum MatchFormat: Int, Codable {
    case individual = 0
    case mixedTeam = 1
    case team = 2
    
    var arrowsPerEnd: Int {
        switch self {
            case .individual: return 3
            case .mixedTeam: return 4
            case .team: return 6
        }
    }
    
    var maxEnds: Int {
        switch self {
            case .individual: return 5
            case .mixedTeam: return 4
            case .team: return 4
        }
    }
}

@available(iOS 26, *)
@Model
final class HeadToHeadMatch: CompetitionStage {
    var label: String
    var targetAssignment: String
    var eliminationType: EliminationType
    
    var opponentName: String = ""
    var opponentArrows: [[ArrowScore]] = [[], [], [], [], []]
    
    var userArrows: [[ArrowScore]] = [[], [], [], [], []]
    
    var userShootOffs: [ArrowScore] = []
    var opponentShootOffs: [ArrowScore] = []
    var manualShootOffWinner: Bool? = nil
    
    var shootOffWinner: Bool? {
        if let manualOverride = manualShootOffWinner { return manualOverride }
        
        let count = min(userShootOffs.count, opponentShootOffs.count)
        guard count > 0 else { return nil }
        
        for i in 0..<count {
            let uArrow = userShootOffs[i]
            let oArrow = opponentShootOffs[i]
            
            if let uX = uArrow.xCoordinate, let uY = uArrow.yCoordinate,
               let oX = oArrow.xCoordinate, let oY = oArrow.yCoordinate {
                let uDist = (uX - 0.5) * (uX - 0.5) + (uY - 0.5) * (uY - 0.5)
                let oDist = (oX - 0.5) * (oX - 0.5) + (oY - 0.5) * (oY - 0.5)
                
                if uDist != oDist { return uDist < oDist }
            }
            
            if uArrow.value != oArrow.value { return uArrow.value > oArrow.value }
            if uArrow.isX != oArrow.isX { return uArrow.isX }
        }
        
        return nil
    }
    
    var matchFormatRaw: Int
    var matchFormat: MatchFormat {
        get { MatchFormat(rawValue: matchFormatRaw) ?? .individual }
        set { matchFormatRaw = newValue.rawValue }
    }
    
    var userTotalScore: Int {
        userArrows.flatMap { $0 }.reduce(0) { $0 + Int($1.value) }
    }
    
    var opponentTotalScore: Int {
        opponentArrows.flatMap { $0 }.reduce(0) { $0 + Int($1.value) }
    }
    
    var userSetPoints: Int { calculateMatchSetPoints(forUser: true) }
    var opponentSetPoints: Int { calculateMatchSetPoints(forUser: false) }
    
    private func calculateMatchSetPoints(forUser: Bool) -> Int {
        guard !eliminationType.isCumulativeScoring else { return 0 }
        
        var uPoints = 0
        var oPoints = 0
        
        for i in 0..<matchFormat.maxEnds {
            let uEnd = userArrows[safe: i] ?? []
            let oEnd = opponentArrows[safe: i] ?? []
            
            if uEnd.isEmpty && oEnd.isEmpty { continue }
            
            let uTotal = uEnd.reduce(0) { $0 + Int($1.value) }
            let oTotal = oEnd.reduce(0) { $0 + Int($1.value) }
            
            if uTotal == oTotal {
                uPoints += 1
                oPoints += 1
            } else if uTotal > oTotal {
                uPoints += 2
            } else {
                oPoints += 2
            }
        }
        
        return forUser ? uPoints : oPoints
    }
    
    init(label: String, dayIndex: UInt = 0, eliminationType: EliminationType, opponentName: String = "", targetAssignment: String = "", matchFormat: MatchFormat = .individual) {
        self.label = label
        self.eliminationType = eliminationType
        self.opponentName = opponentName
        self.targetAssignment = targetAssignment
        self.matchFormatRaw = matchFormat.rawValue
        
        super.init(dayIndex: dayIndex)
    }
}
