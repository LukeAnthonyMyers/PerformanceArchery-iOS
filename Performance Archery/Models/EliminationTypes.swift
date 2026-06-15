//
//  EliminationTypes.swift
//  Performance Archery
//
//  Created by Luke Myers on 07/06/2026.
//

extension EliminationType {
    struct worldArchery {
        static let individual70m = EliminationType(
            name: "Individual Head to Head | 70m",
            format: MatchFormat.individual,
            isCumulativeScoring: false,
            distances: [70],
            isDistanceMetric: true,
            targetSizes: [122],
            isTargetSizeMetric: [true],
            targetFaces: [TargetFace.xTenZone]
        )
        
        static let individualBarebow50m = EliminationType(
            name: "Individual Head to Head | Barebow 50m",
            format: MatchFormat.individual,
            isCumulativeScoring: false,
            distances: [50],
            isDistanceMetric: true,
            targetSizes: [122],
            isTargetSizeMetric: [true],
            targetFaces: [TargetFace.xTenZone]
        )
        
        static let individualCompound50m = EliminationType(
            name: "Individual Head to Head | Compound 50m",
            format: MatchFormat.individual,
            isCumulativeScoring: true,
            distances: [50],
            isDistanceMetric: true,
            targetSizes: [80],
            isTargetSizeMetric: [true],
            targetFaces: [TargetFace.xTenZone]
        )
        
        static let individualRecurve18m = EliminationType(
            name: "Individual Head to Head | Recurve 18m",
            format: MatchFormat.individual,
            isCumulativeScoring: true,
            distances: [18],
            isDistanceMetric: true,
            targetSizes: [40],
            isTargetSizeMetric: [true],
            targetFaces: [TargetFace.tenZone]
        )
    }
}
