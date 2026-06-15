//
//  RoundTypes.swift
//  Performance Archery
//
//  Created by Luke Myers on 08/02/2026.
//

import Foundation

extension RoundType {
    static let worldArchery: [RoundType] = [
        RoundType(
            name: "WA 1440 (90m)",
            distances: [90, 70, 50, 30],
            isDistanceMetric: true,
            discipline: .target,
            targetSizes: [122, 122, 80, 80],
            isTargetSizeMetric: Array(repeating: true, count: 4),
            targetFaces: Array(repeating: .xTenZone, count: 4),
            arrowCounts: [36, 36, 36, 36],
            arrowsPerEnd: 6
        ),
        RoundType(
            name: "WA 1440 (70m)",
            distances: [70, 60, 50, 30],
            isDistanceMetric: true,
            discipline: .target,
            targetSizes: [122, 122, 80, 80],
            isTargetSizeMetric: Array(repeating: true, count: 4),
            targetFaces: Array(repeating: .xTenZone, count: 4),
            arrowCounts: [36, 36, 36, 36],
            arrowsPerEnd: 6
        ),
        RoundType(
            name: "WA 720 (70m)",
            distances: [70],
            isDistanceMetric: true,
            discipline: .target,
            targetSizes: [122],
            isTargetSizeMetric: [true],
            targetFaces: [.xTenZone],
            arrowCounts: [72],
            arrowsPerEnd: 6,
            splitScorecards: true
        ),
        RoundType(
            name: "WA 900",
            distances: [60, 50, 40],
            isDistanceMetric: true,
            discipline: .target,
            targetSizes: [122, 122, 122],
            isTargetSizeMetric: Array(repeating: true, count: 3),
            targetFaces: Array(repeating: .xTenZone, count: 3),
            arrowCounts: [30, 30, 30],
            arrowsPerEnd: 6
        ),
        RoundType(
            name: "WA Combined",
            distances: [25, 18],
            isDistanceMetric: true,
            discipline: .target,
            targetSizes: [60, 40],
            isTargetSizeMetric: Array(repeating: true, count: 2),
            targetFaces: Array(repeating: .tenZone, count: 2),
            arrowCounts: [60, 60],
            arrowsPerEnd: 3,
            splitScorecards: true
        ),
        RoundType(
            name: "WA 25",
            distances: [25],
            isDistanceMetric: true,
            discipline: .target,
            targetSizes: [60],
            isTargetSizeMetric: [true],
            targetFaces: [.tenZone],
            arrowCounts: [60],
            arrowsPerEnd: 3,
            splitScorecards: true
        ),
        RoundType(
            name: "WA 18",
            distances: [18],
            isDistanceMetric: true,
            discipline: .target,
            targetSizes: [40],
            isTargetSizeMetric: [true],
            targetFaces: [.tenZone],
            arrowCounts: [60],
            arrowsPerEnd: 3,
            splitScorecards: true
        )
    ]
    
    static let archeryGB: [RoundType] = [
        RoundType(
            name: "Archery GB Imperial Clout (180 yards)",
            distances: [180],
            isDistanceMetric: false,
            discipline: .target,
            targetSizes: [144],
            isTargetSizeMetric: [false],
            targetFaces: [.imperialClout],
            arrowCounts: [30],
            arrowsPerEnd: 6
        ),
        RoundType(
            name: "York",
            distances: [100, 80, 60],
            isDistanceMetric: false,
            discipline: .target,
            targetSizes: [122, 122, 122],
            isTargetSizeMetric: Array(repeating: false, count: 3),
            targetFaces: Array(repeating: .imperialFiveZone, count: 3),
            arrowCounts: [72, 48, 24],
            arrowsPerEnd: 6
        ),
        RoundType(
            name: "Hereford/Bristol I",
            distances: [80, 60, 50],
            isDistanceMetric: false,
            discipline: .target,
            targetSizes: [122, 122, 122],
            isTargetSizeMetric: Array(repeating: false, count: 3),
            targetFaces: Array(repeating: .imperialFiveZone, count: 3),
            arrowCounts: [72, 48, 24],
            arrowsPerEnd: 6
        ),
        RoundType(
            name: "Portsmouth",
            distances: [20],
            isDistanceMetric: false,
            discipline: .target,
            targetSizes: [60],
            isTargetSizeMetric: [true],
            targetFaces: [.tenZone],
            arrowCounts: [60],
            arrowsPerEnd: 3,
            splitScorecards: true
        ),
        RoundType(
            name: "Vegas",
            distances: [18],
            isDistanceMetric: true,
            discipline: .target,
            targetSizes: [40],
            isTargetSizeMetric: [true],
            targetFaces: [.tenZone],
            arrowCounts: [60],
            arrowsPerEnd: 3,
            splitScorecards: true
        ),
        RoundType(
            name: "Vegas 300",
            distances: [20],
            isDistanceMetric: false,
            discipline: .target,
            targetSizes: [40],
            isTargetSizeMetric: [true],
            targetFaces: [.xTenZone],
            arrowCounts: [30],
            arrowsPerEnd: 3
        ),
    ]
    
    static var allRounds: [RoundType] {
        worldArchery + archeryGB
    }
    
    static func type(named name: String) -> RoundType? {
        allRounds.first {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }
    }
}
