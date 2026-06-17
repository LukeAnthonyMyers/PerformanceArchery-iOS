//
//  H2HScoresheetView.swift
//  Performance Archery
//
//  Created by Luke Myers on 06/06/2026.
//

import SwiftUI

struct H2HScoresheetView: View {
    @Bindable var match: HeadToHeadMatch
    
    let archerName: String?
    let archerCountry: String?
    
    var onSelectEnd: ((H2HTargetEnd, H2HEndInputOverlayView.ActiveArcher) -> Void)? = nil
    
    var requiresShootOff: Bool {
        if match.eliminationType.isCumulativeScoring {
            let userTotal = match.userArrows.flatMap { $0 }.reduce(0) { $0 + Int($1.value) }
            let oppTotal = match.opponentArrows.flatMap { $0 }.reduce(0) { $0 + Int($1.value) }
            return accessibleEnds(match: match) == match.matchFormat.maxEnds && userTotal == oppTotal && userTotal > 0
        } else {
            let uPoints = match.userSetPoints
            let oPoints = match.opponentSetPoints
            return accessibleEnds(match: match) == match.matchFormat.maxEnds && uPoints == oPoints && uPoints > 0
        }
    }
    
    var shootOffRowsCount: Int {
        guard requiresShootOff else { return 0 }
        let currentShotCount = max(match.userShootOffs.count, match.opponentShootOffs.count)
        if currentShotCount == 0 { return 1 }
        
        if match.shootOffWinner == nil && match.userShootOffs.count == currentShotCount && match.opponentShootOffs.count == currentShotCount {
            return currentShotCount + 1
        }
        return currentShotCount
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    H2HTableHeader(arrowsPerEnd: match.matchFormat.arrowsPerEnd)
                    
                    ForEach(0..<accessibleEnds(match: match), id: \.self) { endIdx in
                        H2HRowView(match: match, endIdx: endIdx) { targetIdx, archer in
                            onSelectEnd?(.regular(targetIdx), archer)
                        }
                        
                        Divider()
                    }
                    
                    if requiresShootOff {
                        Text("Shoot-off")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(Color.yellow.opacity(0.3))
                            .border(Color.gray, width: 1)
                        
                        ForEach(0..<shootOffRowsCount, id: \.self) { shootOffIdx in
                            H2HShootOffRowView(match: match, shootOffIdx: shootOffIdx) { targetIdx, archer in
                                onSelectEnd?(.shootOff(targetIdx), archer)
                            }
                            Divider()
                        }
                    }
                }
                .border(Color.gray, width: 1)
            }
            .padding()
        }
    }
}

struct H2HTableHeader: View {
    let arrowsPerEnd: Int
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Arrows").frame(maxWidth: .infinity).font(.caption).bold()
            GridVerticalDivider()
            Text("Score").frame(width: 45).font(.caption).bold()
            GridVerticalDivider()
            Text("Set Pts").frame(width: 65).font(.caption).bold()
            GridVerticalDivider()
            Text("Score").frame(width: 45).font(.caption).bold()
            GridVerticalDivider()
            Text("Opponent").frame(maxWidth: .infinity).font(.caption).bold()
        }
        .padding(.vertical, 8)
        .background(Color.themeHeader)
        .border(Color.gray, width: 1)
    }
}

struct H2HRowView: View {
    let match: HeadToHeadMatch
    let endIdx: Int
    var onSelectEnd: ((Int, H2HEndInputOverlayView.ActiveArcher) -> Void)? = nil
    
    var userSetPoints: Int { runningSetPoints(upTo: endIdx, forUser: true) }
    var oppSetPoints: Int { runningSetPoints(upTo: endIdx, forUser: false) }
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(0..<match.matchFormat.arrowsPerEnd, id: \.self) { i in
                        Text(arrowLabel(for: match.userArrows[safe: endIdx], index: i))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(.vertical, 10)
                .background(Color.themeCell)
                
                GridVerticalDivider()
                
                Text("\(endTotal(for: match.userArrows[safe: endIdx]))")
                    .frame(maxWidth: 45, maxHeight: .infinity).font(.subheadline.bold())
                    .background(Color.themeDistance)
            }
            .contentShape(Rectangle())
            .onTapGesture { onSelectEnd?(endIdx, .user) }
            
            GridVerticalDivider()
            
            Group {
                if match.eliminationType.isCumulativeScoring {
                    HStack(spacing: 0) {
                        Text("\(runningTotal(upTo: endIdx, forUser: true))")
                            .frame(maxWidth: .infinity).foregroundColor(.blue).font(.caption.bold())
                        Text(":")
                            .font(.caption2).foregroundColor(.gray)
                        Text("\(runningTotal(upTo: endIdx, forUser: false))")
                            .frame(maxWidth: .infinity).foregroundColor(.red).font(.caption.bold())
                    }
                } else {
                    HStack(spacing: 0) {
                        Text("\(userSetPoints)").frame(maxWidth: .infinity).foregroundColor(.blue)
                        Text("-").font(.caption2).foregroundColor(.gray)
                        Text("\(oppSetPoints)").frame(maxWidth: .infinity).foregroundColor(.red)
                    }
                    .font(.headline)
                }
            }
            .frame(maxWidth: 65, maxHeight: .infinity)
            .background(endStatusColor())
            
            GridVerticalDivider()
            
            HStack(spacing: 0) {
                Text("\(endTotal(for: match.opponentArrows[safe: endIdx]))")
                    .frame(maxWidth: 45, maxHeight: .infinity).font(.subheadline.bold())
                    .background(Color.themeDistance)
                
                GridVerticalDivider()
                
                HStack(spacing: 0) {
                    ForEach(0..<match.matchFormat.arrowsPerEnd, id: \.self) { i in
                        Text(arrowLabel(for: match.opponentArrows[safe: endIdx], index: i))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(.vertical, 10)
                .background(Color.themeCell)
            }
            .contentShape(Rectangle())
            .onTapGesture { onSelectEnd?(endIdx, .opponent) }
        }
    }
    
    private func arrowLabel(for arrows: [ArrowScore]?, index: Int) -> String {
        guard let arrows = arrows, index < arrows.count else { return "" }
        return arrows[index].displayText
    }
    
    private func endTotal(for arrows: [ArrowScore]?) -> Int {
        return arrows?.reduce(0) { $0 + Int($1.value) } ?? 0
    }
    
    private func runningTotal(upTo index: Int, forUser: Bool) -> Int {
        let targets = forUser ? match.userArrows : match.opponentArrows
        var running = 0
        for i in 0...index {
            if let array = targets[safe: i] {
                running += array.reduce(0) { $0 + Int($1.value) }
            }
        }
        return running
    }
    
    private func runningSetPoints(upTo index: Int, forUser: Bool) -> Int {
        guard match.eliminationType.isCumulativeScoring == false else { return 0 }
        guard index >= 0 else { return 0 }
        var total = 0
        for i in 0...index {
            total += calculateSetPoints(forEnd: i, forUser: forUser)
        }
        return total
    }
    
    private func calculateSetPoints(forEnd index: Int, forUser: Bool) -> Int {
        guard match.eliminationType.isCumulativeScoring == false else { return 0 }
        let uTotal = endTotal(for: match.userArrows[safe: index])
        let oTotal = endTotal(for: match.opponentArrows[safe: index])
        
        if match.userArrows[safe: index]?.isEmpty == true && match.opponentArrows[safe: index]?.isEmpty == true { return 0 }
        if uTotal == oTotal { return 1 }
        if forUser { return uTotal > oTotal ? 2 : 0 }
        return oTotal > uTotal ? 2 : 0
    }
    
    private func calculateSetPoints(forUser: Bool) -> Int {
        return calculateSetPoints(forEnd: endIdx, forUser: forUser)
    }
    
    private func endStatusColor() -> Color {
        let uEnd = match.userArrows[safe: endIdx] ?? []
        let oEnd = match.opponentArrows[safe: endIdx] ?? []
        
        let uTotal = uEnd.reduce(0) { $0 + Int($1.value) }
        let oTotal = oEnd.reduce(0) { $0 + Int($1.value) }
        
        if uTotal > oTotal { return Color.blue.opacity(0.15) }
        else if oTotal > uTotal { return Color.red.opacity(0.15) }
        else { return Color.gray.opacity(0.15) }
    }
}

struct H2HShootOffRowView: View {
    let match: HeadToHeadMatch
    let shootOffIdx: Int
    var onSelectEnd: ((Int, H2HEndInputOverlayView.ActiveArcher) -> Void)? = nil
    
    var body: some View {
        let (shootOffLabel, shootOffColour) = shootOffStatus()
        HStack(spacing: 0) {
            
            HStack(spacing: 0) {
                Text(match.userShootOffs[safe: shootOffIdx]?.displayText ?? "")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.themeCell)
            }
            .contentShape(Rectangle())
            .onTapGesture { onSelectEnd?(shootOffIdx, .user) }
            
            GridVerticalDivider()
            
            Text(shootOffLabel)
                .font(.caption.bold())
                .frame(maxWidth: 65, maxHeight: .infinity)
                .background(shootOffColour)
            
            GridVerticalDivider()
            
            HStack(spacing: 0) {
                Text(match.opponentShootOffs[safe: shootOffIdx]?.displayText ?? "")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.themeCell)
            }
            .contentShape(Rectangle())
            .onTapGesture { onSelectEnd?(shootOffIdx, .opponent) }
        }
    }
    
    private func shootOffStatus() -> (label: String, colour: Color) {
        guard match.userShootOffs.count > shootOffIdx && match.opponentShootOffs.count > shootOffIdx else { return ("-", Color.yellow.opacity(0.15)) }
        
        if shootOffIdx == match.userShootOffs.count - 1 {
            if let winner = match.shootOffWinner {
                return winner ? ("Win", Color.blue.opacity(0.15)) : ("Loss", Color.red.opacity(0.15))
            }
        }
        return ("Tie", Color.yellow.opacity(0.15))
    }
}

struct GridVerticalDivider: View {
    var body: some View {
        Rectangle().fill(Color.gray).frame(width: 1)
    }
}

#Preview {
    let match = HeadToHeadMatch(
        label: "Final",
        eliminationType: EliminationType.worldArchery.individual70m,
        opponentName: "Ki Bo Bae"
    )
    match.userArrows[0] = Array(8..<11).map { ArrowScore(value: $0, isX: false) }
    match.opponentArrows[0] = Array(8..<11).map { ArrowScore(value: $0, isX: false) }
    
    return H2HScoresheetView(
        match: match,
        archerName: "Chang Hye Jin",
        archerCountry: "KOR - Korea"
    )
    .modelContainer(for: [HeadToHeadMatch.self], inMemory: true)
}
