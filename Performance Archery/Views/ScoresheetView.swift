//
//  ScoresheetView.swift
//  Performance Archery
//
//  Created by Luke Myers on 30/05/2026.
//

import SwiftUI

struct ScoresheetView: View {
    let round: CompetitionRound
    let endRange: Range<Int>
    let distanceLabel: String
    
    var isMultipleScorecards: Bool {
        endRange.lowerBound != 0 || endRange.upperBound != round.roundType.arrowCounts.reduce(0, +) / round.roundType.arrowsPerEnd
    }
    
    var onSelectEnd: ((Int) -> Void)? = nil
    
    var arrowsPerRow: Int {
        let perEnd = Int(round.roundType.arrowsPerEnd)
        
        if Int(round.roundType.arrowCounts[0]) / perEnd > 6 && !round.roundType.splitScorecards {
            return perEnd
        }
        return perEnd > 5 ? perEnd / 2 : perEnd
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                let pageStartArrowIdx = endRange.lowerBound * Int(round.roundType.arrowsPerEnd)
                let priorScorecardsTotal = round.arrows.prefix(pageStartArrowIdx).reduce(0) { $0 + Int($1.value) }
                
                VStack(spacing: 0) {
                    ScoresheetTableHeader(arrowsPerRow: arrowsPerRow, distanceLabel: distanceLabel, targetAssignment: round.targetAssignment, priorScorecardsTotal: priorScorecardsTotal, showGrandTotal: isMultipleScorecards)
                    
                    ForEach(endRange, id: \.self) { endIdx in
                        let startIdx = endIdx * Int(round.roundType.arrowsPerEnd)
                        let endIdxClamped = min(startIdx + Int(round.roundType.arrowsPerEnd), round.arrows.count)
                        
                        let endArrows = startIdx < round.arrows.count
                            ? Array(round.arrows[startIdx..<endIdxClamped])
                            : []
                        
                        let pageStartArrowIdx = endRange.lowerBound * Int(round.roundType.arrowsPerEnd)
                        let priorArrowsOnPage = round.arrows.prefix(startIdx).dropFirst(pageStartArrowIdx)
                        let previousPageTotal = priorArrowsOnPage.reduce(0) { $0 + Int($1.value) }
                        
                        let globalPriorArrows = round.arrows.prefix(startIdx)
                        let previousGrandTotal = globalPriorArrows.reduce(0) { $0 + Int($1.value) }
                        
                        ScoresheetEndRow(
                            endNumber: endIdx + 1,
                            arrows: endArrows,
                            arrowsPerEnd: Int(round.roundType.arrowsPerEnd),
                            arrowsPerRow: arrowsPerRow,
                            previousPageTotal: previousPageTotal,
                            previousGrandTotal: previousGrandTotal,
                            showGrandTotal: isMultipleScorecards
                        )
                        .background(Color.themeCell)
                        .onTapGesture {
                            onSelectEnd?(endIdx)
                        }
                    }
                    
                    ScoresheetPageFooter(round: round, endRange: endRange, showGrandTotal: isMultipleScorecards)
                }
            }
            .padding()
        }
    }
}

struct ScoresheetTableHeader: View {
    let arrowsPerRow: Int
    let distanceLabel: String
    let targetAssignment: String
    let division: String = "R W"
    let priorScorecardsTotal: Int
    let showGrandTotal: Bool
    
    var archerDetailsOffset: CGFloat {
        if division.isEmpty {
            return -58
        } else if targetAssignment.isEmpty {
            return -43
        } else {
            return -83
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(distanceLabel)
                .font(.caption).italic()
                .frame(width: 40, height: 40)
                .background(Color.themeDistance)
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(1...arrowsPerRow, id: \.self) { i in
                        Text("\(i)")
                            .font(.headline)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.themeHeader)
                            .border(Color.primary, width: 0.5)
                    }
                    
                    VStack(spacing: 0) {
                        Text("Qualification Round")
                            .font(.system(size: 9, weight: .bold))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.themeHeader)
                            .border(Color.primary, width: 0.5)
                        
                        HStack(spacing: 0) {
                            Text("Sum").font(.subheadline).bold().frame(minWidth: 50, maxHeight: .infinity).border(Color.primary, width: 0.5)
                            Text("Tot.").font(.subheadline).bold().frame(minWidth: 65, maxHeight: .infinity).border(Color.primary, width: 0.5)
                            
                            if showGrandTotal {
                                Text("Total")
                                    .font(.subheadline).bold()
                                    .frame(minWidth: 50, maxHeight: .infinity)
                                    .background(Color.themeGrandTotalHeader)
                                    .border(Color.primary, width: 0.5)
                                    .overlay(alignment: .top) {
                                        if priorScorecardsTotal > 0 {
                                            VStack(spacing: 0) {
                                                Text("Total")
                                                    .font(.subheadline).bold()
                                                    .frame(width: 50, height: 20)
                                                    .background(Color.themeGrandTotalHeader)
                                                    .border(Color.primary, width: 0.5)
                                                Text("\(priorScorecardsTotal)")
                                                    .font(.subheadline).bold()
                                                    .frame(width: 50, height: 20)
                                                    .background(Color.themeGrandTotalHeader)
                                                    .border(Color.primary, width: 0.5)
                                            }
                                            .offset(y: -57.5)
                                        }
                                    }
                            }
                            
                            HStack(spacing: 0) {
                                Text("X").font(.headline).frame(minWidth: 25, maxHeight: .infinity).border(Color.primary, width: 0.5)
                                Text("10").font(.headline).frame(minWidth: 25, maxHeight: .infinity).border(Color.primary, width: 0.5)
                            }
                            .overlay(alignment: .top) {
                                VStack(spacing: 0) {
                                    if !targetAssignment.isEmpty {
                                        Text(targetAssignment)
                                            .font(.title2).bold()
                                            .frame(height: 40)
                                    }
                                    
                                    if !targetAssignment.isEmpty || !division.isEmpty {
                                        Divider().background(Color.primary)
                                    }
                                    
                                    if !division.isEmpty {
                                        Text(division)
                                            .font(.footnote).bold()
                                            .frame(height: 25)
                                    }
                                }
                                .background(Color.themeHeader)
                                .border(Color.primary, width: 0.5)
                                .offset(y: archerDetailsOffset)
                            }
                        }
                        .frame(height: 22)
                        .background(Color.themeHeader)
                    }
                    .frame(minWidth: showGrandTotal ? 215 : 165, maxHeight: .infinity)
                }
            }
        }
        .frame(minHeight: 40)
        .padding(.top, abs(archerDetailsOffset))
    }
}

struct ScoresheetEndRow: View {
    let endNumber: Int
    let arrows: [ArrowScore]
    let arrowsPerEnd: Int
    let arrowsPerRow: Int
    let previousPageTotal: Int
    let previousGrandTotal: Int
    let showGrandTotal: Bool
    
    var body: some View {
        let isSplit = arrowsPerEnd > arrowsPerRow
        let endTotal = arrows.reduce(0) { $0 + Int($1.value) }
        
        HStack(spacing: 0) {
            Text("\(endNumber)")
                .font(.headline)
                .frame(minWidth: 40, maxHeight: .infinity)
                .background(Color.themeHeader)
                .border(Color.primary, width: 0.5)
            
            if isSplit {
                VStack(spacing: 0) {
                    let half1 = Array(arrows.prefix(arrowsPerRow))
                    let half2 = arrows.count > arrowsPerRow ? Array(arrows.suffix(from: arrowsPerRow)) : []
                    
                    DualAccumulatorHalfRow(arrows: half1, maxArrows: arrowsPerRow, isFirstHalf: true, endTotal: 0, pageRunningTotal: 0, grandRunningTotal: 0, showGrandTotal: showGrandTotal)
                    DualAccumulatorHalfRow(arrows: half2, maxArrows: arrowsPerRow, isFirstHalf: false, endTotal: endTotal, pageRunningTotal: previousPageTotal + endTotal, grandRunningTotal: previousGrandTotal + endTotal, showGrandTotal: showGrandTotal)
                }
            } else {
                DualAccumulatorHalfRow(arrows: arrows, maxArrows: arrowsPerRow, isFirstHalf: false, endTotal: endTotal, pageRunningTotal: previousPageTotal + endTotal, grandRunningTotal: previousGrandTotal + endTotal, showGrandTotal: showGrandTotal)
            }
        }
    }
}

struct DualAccumulatorHalfRow: View {
    let arrows: [ArrowScore]
    let maxArrows: Int
    let isFirstHalf: Bool
    let endTotal: Int
    let pageRunningTotal: Int
    let grandRunningTotal: Int
    let showGrandTotal: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<maxArrows, id: \.self) { i in
                Text(i < arrows.count ? arrows[i].displayText : "")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .border(Color.primary, width: 0.5)
            }
            
            let halfSum = arrows.reduce(0) { $0 + Int($1.value) }
            Text(halfSum > 0 || !arrows.isEmpty ? "\(halfSum)" : "")
                .font(.headline)
                .frame(minWidth: 50, maxHeight: .infinity)
                .border(Color.primary, width: 0.5)
            
            if isFirstHalf {
                CrossedOutBox()
                    .frame(width: 65)
                    .border(Color.primary, width: 0.5)
                
                if showGrandTotal {
                    CrossedOutBox()
                        .frame(width: 50)
                        .border(Color.primary, width: 0.5)
                        .background(Color.themeGrandTotalHeader)
                }
            } else {
                HStack(spacing: 0) {
                    Text(endTotal > 0 || !arrows.isEmpty ? "\(endTotal)" : "").frame(minWidth: 30, maxHeight: .infinity).border(Color.primary, width: 0.5)
                    Text(pageRunningTotal > 0 || !arrows.isEmpty ? "\(pageRunningTotal)" : "").frame(minWidth: 35, maxHeight: .infinity).border(Color.primary, width: 0.5)
                    
                    if showGrandTotal {
                        Text(grandRunningTotal > 0 || !arrows.isEmpty ? grandRunningTotal.formatted(.number.grouping(.never)) : "")
                            .frame(minWidth: 50, maxHeight: .infinity)
                            .background(Color.themeGrandTotalCell)
                            .border(Color.primary, width: 0.5)
                    }
                }
            }
            
            let xCount = arrows.filter { $0.isX }.count
            let tenCount = arrows.filter { $0.value == 10 && !$0.isX }.count
            
            Text(xCount > 0 ? "\(xCount)" : "").font(.caption).frame(minWidth: 25, maxHeight: .infinity).border(Color.primary, width: 0.5)
            Text(tenCount > 0 ? "\(tenCount)" : "").font(.caption).frame(minWidth: 25, maxHeight: .infinity).border(Color.primary, width: 0.5)
        }
        .frame(height: 35)
    }
}

struct HalfRow: View {
    let arrows: [ArrowScore]
    let maxArrows: Int
    let isFirstHalf: Bool
    let endTotal: Int
    let runningTotal: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<maxArrows, id: \.self) { i in
                Text(i < arrows.count ? arrows[i].displayText : "")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .border(Color.primary, width: 0.5)
            }
            
            let sum = arrows.reduce(0) { $0 + $1.value }
            Text(sum > 0 || !arrows.isEmpty ? "\(sum)" : "")
                .frame(minWidth: 40, maxHeight: .infinity)
                .border(Color.primary, width: 0.5)
            
            if isFirstHalf {
                CrossedOutBox()
                    .frame(width: 90)
                    .border(Color.primary, width: 0.5)
            } else {
                HStack(spacing: 0) {
                    Text(endTotal > 0 || !arrows.isEmpty ? "\(endTotal)" : "")
                        .frame(minWidth: 40, maxHeight: .infinity)
                        .border(Color.primary, width: 0.5)
                    
                    Text(runningTotal > 0 || !arrows.isEmpty ? "\(runningTotal)" : "")
                        .frame(minWidth: 50, maxHeight: .infinity)
                        .border(Color.primary, width: 0.5)
                }
            }
            
            let xCount = arrows.filter { $0.isX }.count
            let tenCount = arrows.filter { $0.value == 10 && !$0.isX }.count
            
            Text(xCount > 0 ? "\(xCount)" : "")
                .frame(minWidth: 30, maxHeight: .infinity)
                .border(Color.primary, width: 0.5)
            
            Text(tenCount > 0 ? "\(tenCount)" : "")
                .frame(minWidth: 30, maxHeight: .infinity)
                .border(Color.primary, width: 0.5)
        }
        .frame(height: 35)
    }
    
    private func arrowText(for index: Int) -> String {
        guard index < arrows.count else { return "" }
        let val = arrows[index].value
        if val == 0 { return "M" }
        return "\(val)"
    }
}

struct ScoresheetPageFooter: View {
    let round: CompetitionRound
    let endRange: Range<Int>
    let showGrandTotal: Bool
    
    var body: some View {
        let arrowsPerEnd = Int(round.roundType.arrowsPerEnd)
        let pageStartIdx = endRange.lowerBound * arrowsPerEnd
        let pageEndIdx = min(endRange.upperBound * arrowsPerEnd, round.arrows.count)
        
        let pageArrows = pageStartIdx < round.arrows.count ? Array(round.arrows[pageStartIdx..<pageEndIdx]) : []
        
        let pageScore = pageArrows.reduce(0) { $0 + Int($1.value) }
        let pageX = pageArrows.filter { $0.isX }.count
        let page10 = pageArrows.filter { $0.value == 10 && !$0.isX }.count
        let accumulatedGrandTotal = round.arrows.prefix(pageEndIdx).reduce(0) { $0 + Int($1.value) }
        
        return HStack(spacing: 0) {
                    Text("Total")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 12)
                    
                    HStack(spacing: 0) {
                        Text("\(pageScore)")
                            .font(.subheadline).bold()
                            .frame(width: 35, height: 35)
                            .background(Color.themeHeader)
                            .border(Color.primary, width: 0.5)
                        
                        if showGrandTotal {
                            Text(accumulatedGrandTotal.formatted(.number.grouping(.never)))
                                .font(.subheadline).bold()
                                .frame(width: 50, height: 35)
                                .background(Color.themeGrandTotalCell)
                                .border(Color.primary, width: 0.5)
                        }
                        
                        Text(pageX > 0 ? "\(pageX)" : "").font(.caption.bold()).frame(width: 25, height: 35).background(Color.themeHeader).border(Color.primary, width: 0.5)
                        Text(page10 > 0 ? "\(page10)" : "").font(.caption.bold()).frame(width: 25, height: 35).background(Color.themeHeader).border(Color.primary, width: 0.5)
                    }
                    .border(Color.primary, width: 0.5)
                }
                .frame(height: 35)
    }
}

struct CrossedOutBox: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                path.move(to: CGPoint(x: geo.size.width, y: 0))
                path.addLine(to: CGPoint(x: 0, y: geo.size.height))
            }
            .stroke(Color.gray, lineWidth: 0.5)
        }
    }
}

extension Color {
    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }
    
    static let themeCell = dynamic(light: .white, dark: UIColor(white: 0.15, alpha: 1.0))
    static let themeDistance = dynamic(light: UIColor(white: 0.95, alpha: 1.0), dark: UIColor(white: 0.45, alpha: 1.0))
    static let themeHeader = dynamic(light: UIColor(white: 0.88, alpha: 1.0), dark: UIColor(white: 0.22, alpha: 1.0))
    static let themeGrandTotalHeader = dynamic(light: UIColor(red: 1.0, green: 0.88, blue: 0.89, alpha: 1.0), dark: UIColor(red: 0.45, green: 0.2, blue: 0.25, alpha: 1.0))
    static let themeGrandTotalCell = dynamic(light: UIColor(red: 1.0, green: 0.92, blue: 0.93, alpha: 1.0), dark: UIColor(red: 0.35, green: 0.15, blue: 0.18, alpha: 1.0))
}

#Preview {
    ScoresheetView(
        round: CompetitionRound(roundType: RoundType.worldArchery[2],
                                targetAssignment: "121A",
                                arrows: Array(0..<11).map { ArrowScore(value: $0, isX: false) }),
        endRange: 0..<6,
        distanceLabel: "70m"
    )
}

