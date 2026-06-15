//
//  TargetFaces.swift
//  Performance Archery
//
//  Created by Luke Myers on 24/05/2026.
//

extension TargetFace {
    static let tenZone = TargetFace(
        name: "Standard 10-Zone",
        backgroundColour: .white,
        zones: [
            ring(score: 1, fill: .white, border: .black, inner: 0.9, outer: 1.0),
            ring(score: 2, fill: .white, border: .black, inner: 0.8, outer: 0.9),

            ring(score: 3, fill: .black, border: .white, inner: 0.7, outer: 0.8),
            ring(score: 4, fill: .black, border: .white, inner: 0.6, outer: 0.7),

            ring(score: 5, fill: .blue, border: .black, inner: 0.5, outer: 0.6),
            ring(score: 6, fill: .blue, border: .black, inner: 0.4, outer: 0.5),

            ring(score: 7, fill: .red, border: .black, inner: 0.3, outer: 0.4),
            ring(score: 8, fill: .red, border: .black, inner: 0.2, outer: 0.3),

            ring(score: 9, fill: .yellow,  border: .black, inner: 0.1, outer: 0.2),
            ring(score: 10, fill: .yellow, border: .black, inner: 0.0, outer: 0.1)
        ]
    )
    
    static let xTenZone = TargetFace(
        name: "10-Zone with X",
        backgroundColour: .white,
        zones: [
            ring(score: 1, fill: .white, border: .black, inner: 0.9, outer: 1.0),
            ring(score: 2, fill: .white, border: .black, inner: 0.8, outer: 0.9),

            ring(score: 3, fill: .black, border: .white, inner: 0.7, outer: 0.8),
            ring(score: 4, fill: .black, border: .white, inner: 0.6, outer: 0.7),

            ring(score: 5, fill: .blue, border: .black, inner: 0.5, outer: 0.6),
            ring(score: 6, fill: .blue, border: .black, inner: 0.4, outer: 0.5),

            ring(score: 7, fill: .red, border: .black, inner: 0.3, outer: 0.4),
            ring(score: 8, fill: .red, border: .black, inner: 0.2, outer: 0.3),

            ring(score: 9,  fill: .yellow, border: .black, inner: 0.1,  outer: 0.2),
            ring(score: 10, fill: .yellow, border: .black, inner: 0.05, outer: 0.1),
            ring(score: 10, fill: .yellow, border: .black, inner: 0.0,  outer: 0.05, specialName: "X")
        ]
    )
    
    static let imperialFiveZone = TargetFace(
        name: "Imperial 5-Zone",
        backgroundColour: .white,
        zones: [
            ring(score: 1, fill: .white,  border: .black, inner: 0.8, outer: 1.0),
            ring(score: 3, fill: .black,  border: .white, inner: 0.6, outer: 0.8),
            ring(score: 5, fill: .blue,   border: .black, inner: 0.4, outer: 0.6),
            ring(score: 7, fill: .red,    border: .black, inner: 0.2, outer: 0.4),
            ring(score: 9, fill: .yellow, border: .black, inner: 0.0, outer: 0.2)
        ]
    )
    
    static let imperialClout = TargetFace(
        name: "Imperial Clout",
        backgroundColour: .green,
        zones: [
            ring(score: 1, fill: .white,  border: .black, inner: 0.75, outer: 1.00),
            ring(score: 2, fill: .black,  border: .black, inner: 0.50, outer: 0.75),
            ring(score: 3, fill: .blue,   border: .black, inner: 0.25, outer: 0.50),
            ring(score: 4, fill: .red,    border: .black, inner: 0.125, outer: 0.25),
            ring(score: 5, fill: .yellow, border: .black, inner: 0.00,  outer: 0.125)
        ]
    )

    private static func ring(
        score: Int,
        fill: CodableColour,
        border: CodableColour,
        inner: Double,
        outer: Double,
        center: Point = Point(x: 0.5, y: 0.5),
        specialName: String? = nil
    ) -> TargetZone {
        TargetZone(
            score: score,
            fillColour: fill,
            borderColour: border,
            center: center,
            innerRadiusRatio: inner,
            outerRadiusRatio: outer,
            specialName: specialName
        )
    }
}
