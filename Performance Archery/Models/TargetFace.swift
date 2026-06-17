//
//  TargetFace.swift
//  Performance Archery
//
//  Created by Luke Myers on 24/05/2026.
//

import SwiftUI

struct TargetFace: Codable, Hashable {
    var name: String
    var backgroundColour: CodableColour
    var zones: [TargetZone]
}

struct TargetZone: Codable, Hashable {
    var score: Int
    var fillColour: CodableColour
    var borderColour: CodableColour

    var center: Point

    var innerRadiusRatio: Double
    var outerRadiusRatio: Double
    
    var specialName: String?
}

struct Point: Codable, Hashable {
    var x: Double
    var y: Double
}

struct StrokeSpec: Codable, Hashable {
    var colour: CodableColour
    var lineWidthRatio: Double
}

struct CodableColour: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double = 1.0

    var swiftUIColour: Color {
        Color(
            .sRGB,
            red: red,
            green: green,
            blue: blue,
            opacity: opacity
        )
    }
}

extension CodableColour {
    static let white = CodableColour(
        red: 0.95,
        green: 0.95,
        blue: 0.92
    )

    static let black = CodableColour(
        red: 0.12,
        green: 0.12,
        blue: 0.13
    )

    static let blue = CodableColour(
        red: 0.00,
        green: 0.42,
        blue: 0.75
    )

    static let red = CodableColour(
        red: 0.82,
        green: 0.12,
        blue: 0.16
    )

    static let yellow = CodableColour(
        red: 0.96,
        green: 0.78,
        blue: 0.10
    )

    static let green = CodableColour(
        red: 0.18,
        green: 0.55,
        blue: 0.28
    )
}
