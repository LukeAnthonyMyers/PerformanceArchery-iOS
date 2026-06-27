//
//  TargetFaceView.swift
//  Performance Archery
//
//  Created by Luke Myers on 24/05/2026.
//

import SwiftUI

struct ScorecardSegment: Identifiable {
    let id = UUID()
    let label: String
    let endsRange: Range<Int>
}

struct ScoringView: View {
    let round: CompetitionRound
    
    @State private var activeCardTabIndex: Int = 0
    @State private var activeEndIndex: Int? = nil
    
    var segments: [ScorecardSegment] {
        let arrowsPerEnd = Int(round.roundType.arrowsPerEnd)
        
        if round.roundType.distances.count > 1 {
            var currentEndOffset = 0
            
            return round.roundType.distances.indices.map { idx in
                let distance = round.roundType.distances[idx]
                let arrowCount = Int(round.roundType.arrowCounts[idx])
                let endsForDistance = arrowCount / arrowsPerEnd
                let range = currentEndOffset..<(currentEndOffset + endsForDistance)
                currentEndOffset += endsForDistance
                
                return ScorecardSegment(label: "\(distance)m", endsRange: range)
            }
        } else if round.roundType.splitScorecards {
            let totalArrows = Int(round.roundType.arrowCounts.reduce(0, +))
            let totalEnds = totalArrows / arrowsPerEnd
            let midPoint = totalEnds / 2
            let dist = round.roundType.distances.first ?? 50
            
            return [
                ScorecardSegment(label: "\(dist)m-1", endsRange: 0..<midPoint),
                ScorecardSegment(label: "\(dist)m-2", endsRange: midPoint..<totalEnds)
            ]
        } else {
            let totalArrows = Int(round.roundType.arrowCounts.reduce(0, +))
            let totalEnds = max(6, totalArrows / arrowsPerEnd)
            let dist = round.roundType.distances.first ?? 50
            
            return [ScorecardSegment(label: "\(dist)m", endsRange: 0..<totalEnds)]
        }
    }
    
    var body: some View {
        VStack {
            TabView(selection: $activeCardTabIndex) {
                ForEach(segments.indices, id: \.self) { idx in
                    ScrollView {
                        ScoresheetView(
                            round: round,
                            endRange: segments[idx].endsRange,
                            distanceLabel: segments[idx].label
                        ) { selectedEnd in
                            activeEndIndex = selectedEnd
                        }
                    }
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .navigationTitle("Scoresheet | \(round.roundType.name)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: Binding(
                get: { activeEndIndex != nil },
                set: { if !$0 { activeEndIndex = nil } }
            )) {
                if activeEndIndex != nil {
                    EndInputOverlayView(
                        round: round,
                        endIndex: Binding(
                            get: { activeEndIndex ?? 0 },
                            set: { activeEndIndex = $0 }
                        ),
                        totalEndsCount: segments.reduce(0) { $0 + $1.endsRange.count }
                    )
                }
            }
            .onChange(of: activeEndIndex) { _, newIndex in
                if let newIndex = newIndex, let matchedTabIdx = segments.firstIndex(where: { $0.endsRange.contains(newIndex) }) {
                    activeCardTabIndex = matchedTabIdx
                }
            }
    }
}

struct EndInputOverlayView: View {
    let round: CompetitionRound
    @Binding var endIndex: Int
    let totalEndsCount: Int
    
    @State private var scoringType = "Target Face"
    @State private var selectedArrowSlot: Int = 0
    
    var arrowsPerEnd: Int { Int(round.roundType.arrowsPerEnd) }
    
    var currentEndArrows: [ArrowScore] {
        let startIdx = endIndex * arrowsPerEnd
        let endIdx = min(startIdx + arrowsPerEnd, round.arrows.count)
        if startIdx < round.arrows.count {
            return Array(round.arrows[startIdx..<endIdx])
        }
        return []
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(0..<arrowsPerEnd, id: \.self) { slotIndex in
                    let arrowExists = slotIndex < currentEndArrows.count
                    let isSelected = slotIndex == selectedArrowSlot
                    
                    VStack {
                        Text("\(slotIndex + 1)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(arrowExists ? currentEndArrows[slotIndex].displayText : "")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, minHeight: 45)
                            .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                            )
                    }
                    .onTapGesture {
                        selectedArrowSlot = slotIndex
                    }
                }
                
                Button(action: deleteSelectedOrPrevious) {
                    Image(systemName: "delete.left")
                        .font(.title2)
                        .frame(width: 45, height: 45)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            
            Picker("Input Mode", selection: $scoringType) {
                Text("Target Face").tag("Target Face")
                Text("Keypad").tag("Keypad")
            }
            .pickerStyle(.segmented)
            .padding()
            
            Spacer()
            
            if scoringType == "Keypad" {
                KeypadInputView(face: round.roundType.targetFaces[0]) { value, isX in
                    saveArrowToSlot(ArrowScore(value: value, isX: isX))
                }
                .transition(.opacity)
            } else {
                InteractivePlottingFaceView(face: round.roundType.targetFaces[0], arrows: currentEndArrows) { value, isX, x, y in
                    saveArrowToSlot(ArrowScore(value: value, isX: isX, x: x, y: y))
                }
                .padding(.bottom, 20)
                .transition(.opacity)
            }
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 16) {
                    Button(action: { if endIndex > 0 { endIndex -= 1 } }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .foregroundColor(endIndex > 0 ? .blue : .gray.opacity(0.3))
                    }
                    .disabled(endIndex == 0)
                    
                    Text("End \(endIndex + 1)").font(.headline).frame(minWidth: 70)
                    
                    Button(action: { if endIndex < totalEndsCount - 1 { endIndex += 1 } }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .foregroundColor(endIndex < totalEndsCount - 1 ? .blue : .gray.opacity(0.3))
                    }
                    .disabled(endIndex == totalEndsCount - 1)
                }
            }
        }
        .onAppear { autoFocusNextSlot() }
        .onChange(of: endIndex) { autoFocusNextSlot() }
    }
    
    private func autoFocusNextSlot() {
        selectedArrowSlot = currentEndArrows.count < arrowsPerEnd ? currentEndArrows.count : arrowsPerEnd - 1
    }
    
    private func saveArrowToSlot(_ arrow: ArrowScore) {
        let masterIdx = (endIndex * arrowsPerEnd) + selectedArrowSlot
        
        if masterIdx < round.arrows.count {
            round.arrows[masterIdx] = arrow
        } else {
            while round.arrows.count < masterIdx {
                round.arrows.append(ArrowScore(value: 0))
            }
            
            round.arrows.append(arrow)
        }
        
        if selectedArrowSlot < arrowsPerEnd - 1 {
            selectedArrowSlot += 1
        } else if endIndex < totalEndsCount - 1 {
            endIndex += 1
            selectedArrowSlot = 0
        }
    }
    
    private func deleteSelectedOrPrevious() {
        let masterIdx = (endIndex * arrowsPerEnd) + selectedArrowSlot
        
        if masterIdx < round.arrows.count {
            round.arrows.remove(at: masterIdx)
        } else if selectedArrowSlot > 0 {
            selectedArrowSlot -= 1
            let prevMasterIdx = (endIndex * arrowsPerEnd) + selectedArrowSlot
            
            if prevMasterIdx < round.arrows.count {
                round.arrows.remove(at: prevMasterIdx)
            }
        }
    }
}


struct KeypadInputView: View {
    let face: TargetFace
    let onButtonTap: (UInt8, Bool) -> Void
    
    struct KeypadButtonData: Hashable {
        let label: String
        let value: UInt8
        let isX: Bool
        let bg: Color
        let text: Color
    }
    
    var buttonGrid: [[KeypadButtonData]] {
        var buttons: [KeypadButtonData] = []
        var seenLabels = Set<String>()
        
        let sortedZones = face.zones.sorted {
            if $0.score == $1.score {
                return ($0.specialName == "X") && ($1.specialName != "X")
            }
            return $0.score > $1.score
        }
        
        for zone in sortedZones {
            let isX = zone.specialName == "X"
            let label = isX ? "X" : "\(zone.score)"
            
            if !seenLabels.contains(label) {
                seenLabels.insert(label)
                
                let colourIsBlack = zone.fillColour == .black
                let textColour: Color = colourIsBlack ? .white : zone.borderColour.swiftUIColour
                
                buttons.append(KeypadButtonData(
                    label: label,
                    value: UInt8(zone.score),
                    isX: isX,
                    bg: zone.fillColour.swiftUIColour,
                    text: textColour
                ))
            }
        }
        
        buttons.append(KeypadButtonData(label: "M", value: 0, isX: false, bg: Color(.systemGray4), text: .primary))
        
        var grid: [[KeypadButtonData]] = []
        
        for i in stride(from: 0, to: buttons.count, by: 3) {
            let end = min(i + 3, buttons.count)
            grid.append(Array(buttons[i..<end]))
        }
        
        return grid
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(buttonGrid, id: \.self) { row in
                HStack(spacing: 20) {
                    ForEach(row, id: \.self) { btn in
                        Button(action: { onButtonTap(btn.value, btn.isX) }) {
                            Text(btn.label)
                                .font(.title.bold())
                                .frame(width: 85, height: 65)
                                .background(btn.bg)
                                .foregroundColor(btn.text)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct InteractivePlottingFaceView: View {
    let face: TargetFace
    let arrows: [ArrowScore]
    var onPlotArrow: (UInt8, Bool, Double, Double) -> Void
    
    @State private var isDragging = false
    @State private var dragPosition: CGPoint = .zero
    @State private var targetSize: CGSize = .zero
    @State private var currentHoverValue: String? = nil
    
    var body: some View {
        GeometryReader { fullGeo in
            ZStack {
                TargetFaceView(face: face)
                    .overlay(
                        ForEach(arrows.indices, id: \.self) { idx in
                            if let xRatio = arrows[idx].xCoordinate, let yRatio = arrows[idx].yCoordinate {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                    .position(x: CGFloat(xRatio) * fullGeo.size.width, y: CGFloat(yRatio) * fullGeo.size.height)
                            }
                        }
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { state in
                                isDragging = true
                                targetSize = fullGeo.size
                                
                                let clampedX = max(0, min(state.location.x, fullGeo.size.width))
                                let clampedY = max(0, min(state.location.y, fullGeo.size.height))
                                dragPosition = CGPoint(x: clampedX, y: clampedY)
                                
                                let hit = computeHit(at: state.location, in: fullGeo.size)
                                currentHoverValue = hit.isX ? "X" : (hit.score == 0 ? "M" : "\(hit.score)")
                            }
                            .onEnded { state in
                                isDragging = false
                                currentHoverValue = nil
                                
                                let clampedX = max(0, min(state.location.x, fullGeo.size.width))
                                let clampedY = max(0, min(state.location.y, fullGeo.size.height))
                                let finalPosition = CGPoint(x: clampedX, y: clampedY)
                                                                
                                let hit = computeHit(at: finalPosition, in: fullGeo.size)
                                let relX = Double(finalPosition.x / fullGeo.size.width)
                                let relY = Double(finalPosition.y / fullGeo.size.height)
                                
                                onPlotArrow(hit.score, hit.isX, relX, relY)
                            }
                    )
                
                if isDragging {
                    MagnifyingLoupeWidget(face: face, arrows: arrows, focusPoint: dragPosition, parentSize: targetSize, hoverValue: currentHoverValue)
                        .position(x: dragPosition.x, y: dragPosition.y - 90)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(30)
    }
    
    private func computeHit(at coordinate: CGPoint, in size: CGSize) -> (score: UInt8, isX: Bool) {
        let relativeX = Double(coordinate.x / size.width)
        let relativeY = Double(coordinate.y / size.height)
        let deltaX = relativeX - 0.5
        let deltaY = relativeY - 0.5
        let absoluteDistanceFromCenter = sqrt((deltaX * deltaX) + (deltaY * deltaY))
        let normalizedRadius = absoluteDistanceFromCenter / 0.45
        
        for zone in face.zones.reversed() {
            if normalizedRadius >= zone.innerRadiusRatio && normalizedRadius <= zone.outerRadiusRatio {
                return (UInt8(zone.score), zone.specialName == "X")
            }
        }
        return (0, false)
    }
}

struct MagnifyingLoupeWidget: View {
    let face: TargetFace
    let arrows: [ArrowScore]
    let focusPoint: CGPoint
    let parentSize: CGSize
    let hoverValue: String?
    
    var body: some View {
        let isOnBlack = ringAtFocusIsBlack()
        
        ZStack {
            ZStack {
                TargetFaceView(face: face)
                    .overlay(
                        ForEach(arrows.indices, id: \.self) { idx in
                            if let xRatio = arrows[idx].xCoordinate, let yRatio = arrows[idx].yCoordinate {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                    .position(x: CGFloat(xRatio) * parentSize.width, y: CGFloat(yRatio) * parentSize.height)
                            }
                        }
                    )
                    .offset(x: parentSize.width / 2 - focusPoint.x, y: parentSize.height / 2 - focusPoint.y)
                    .frame(width: parentSize.width, height: parentSize.height)
                    .scaleEffect(2.5)
                
                Circle()
                    .stroke(isOnBlack ? Color.white : Color.black, lineWidth: 1.5)
                    .frame(width: 15, height: 15)
                    .overlay(
                        Circle()
                            .fill(isOnBlack ? Color.white : Color.black)
                            .frame(width: 3, height: 3)
                    )
            }
            .frame(width: 150, height: 150)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 3.5).shadow(radius: 6))
            
            if let val = hoverValue {
                Text(val)
                    .font(.title3.bold())
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white).shadow(radius: 4))
                    .offset(y: -75)
            }
        }
    }
    
    private func ringAtFocusIsBlack() -> Bool {
        let relativeX = Double(focusPoint.x / max(parentSize.width, 1))
        let relativeY = Double(focusPoint.y / max(parentSize.height, 1))
        let deltaX = relativeX - 0.5
        let deltaY = relativeY - 0.5
        let absoluteDistanceFromCenter = sqrt((deltaX * deltaX) + (deltaY * deltaY))
        let normalizedRadius = absoluteDistanceFromCenter / 0.45
        
        for zone in face.zones {
            if normalizedRadius >= zone.innerRadiusRatio && normalizedRadius <= zone.outerRadiusRatio {
                return zone.fillColour == .black
            }
        }
        return false
    }
}

struct TargetFaceView: View {
    let face: TargetFace

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let diameter = min(width, height) * 0.9

            ZStack {
                face.backgroundColour.swiftUIColour

                ForEach(face.zones.indices, id: \.self) { index in
                    let zone = face.zones[index]

                    let x = CGFloat(zone.center.x) * width
                    let y = CGFloat(zone.center.y) * height
                    let outer = CGFloat(zone.outerRadiusRatio) * diameter
                    let inner = CGFloat(zone.innerRadiusRatio) * diameter

                    Circle()
                        .fill(zone.fillColour.swiftUIColour)
                        .frame(width: outer, height: outer)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    zone.borderColour.swiftUIColour,
                                    lineWidth: 0.25
                                )
                        )
                        .position(x: x, y: y)

                    Circle()
                        .fill(face.backgroundColour.swiftUIColour)
                        .frame(width: inner, height: inner)
                        .position(x: x, y: y)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    NavigationStack {
        ScoringView(round: CompetitionRound(roundType: RoundType.worldArchery[2],
                                            targetAssignment: "12A",
                                            arrows: Array(0..<11).map { ArrowScore(value: $0, isX: false) })
        )
    }
}
