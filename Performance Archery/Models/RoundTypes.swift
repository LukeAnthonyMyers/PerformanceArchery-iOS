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
            isMetric: true,
            discipline: .target,
            targetFaces: ["122cm", "122cm", "80cm", "80cm"],
            arrowCounts: [36, 36, 36, 36]
        ),
        RoundType(
            name: "WA 1440 (70m)",
            distances: [70, 60, 50, 30],
            isMetric: true,
            discipline: .target,
            targetFaces: ["122cm", "122cm", "80cm", "80cm"],
            arrowCounts: [36, 36, 36, 36]
        ),
        RoundType(
            name: "WA 720 (70m)",
            distances: [70],
            isMetric: true,
            discipline: .target,
            targetFaces: ["122cm"],
            arrowCounts: [72]
        ),
        RoundType(
            name: "WA 900",
            distances: [60, 50, 40],
            isMetric: true,
            discipline: .target,
            targetFaces: ["122cm"],
            arrowCounts: [30, 30, 30]
        ),
        RoundType(
            name: "WA Combined",
            distances: [25, 18],
            isMetric: true,
            discipline: .target,
            targetFaces: ["60cm Full Face", "40cm Triple Vertical Face"],
            arrowCounts: [60, 60]
        ),
        RoundType(
            name: "WA 25",
            distances: [25],
            isMetric: true,
            discipline: .target,
            targetFaces: ["60cm Full Face"],
            arrowCounts: [60]
        ),
        RoundType(
            name: "WA 18",
            distances: [18],
            isMetric: true,
            discipline: .target,
            targetFaces: ["40cm Triple Vertical Face"],
            arrowCounts: [60]
        )
    ]
    
    static let archeryGB: [RoundType] = [
        RoundType(
            name: "Archery GB Imperial Clout (180 yards)",
            distances: [180],
            isMetric: false,
            discipline: .target,
            targetFaces: ["12ft ring"],
            arrowCounts: [30]
        ),
        RoundType(
            name: "York",
            distances: [100, 80, 60],
            isMetric: false,
            discipline: .target,
            targetFaces: ["122cm Imperial", "122cm Imperial", "122cm Imperial"],
            arrowCounts: [72, 48, 24]
        ),
        RoundType(
            name: "Hereford/Bristol I",
            distances: [80, 60, 50],
            isMetric: false,
            discipline: .target,
            targetFaces: ["122cm Imperial", "122cm Imperial", "122cm Imperial"],
            arrowCounts: [72, 48, 24]
        ),
        RoundType(
            name: "Portsmouth",
            distances: [20],
            isMetric: false,
            discipline: .target,
            targetFaces: ["60cm"],
            arrowCounts: [60]
        ),
        RoundType(
            name: "Vegas",
            distances: [18],
            isMetric: true,
            discipline: .target,
            targetFaces: ["40cm Triple Triangular Face"],
            arrowCounts: [60]
        ),
        RoundType(
            name: "Vegas 300",
            distances: [20],
            isMetric: false,
            discipline: .target,
            targetFaces: ["40cm Triple Triangular Face"],
            arrowCounts: [30]
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
