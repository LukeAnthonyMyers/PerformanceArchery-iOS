//
//  H2HScoringView.swift
//  Performance Archery
//
//  Created by Luke Myers on 07/06/2026.
//

import SwiftUI

enum H2HTargetEnd: Hashable {
    case regular(Int)
    case shootOff(Int)
}

func accessibleEnds(match: HeadToHeadMatch) -> Int {
    if match.eliminationType.isCumulativeScoring {
        return match.matchFormat.maxEnds
    } else {
        var uPoints = 0
        var oPoints = 0
        var minEnds = 3
        
        let winningPoints = match.matchFormat == .individual ? 6 : 5
        
        for i in 0..<match.matchFormat.maxEnds {
            let uEnd = match.userArrows[safe: i] ?? []
            let oEnd = match.opponentArrows[safe: i] ?? []
            
            if uEnd.isEmpty && oEnd.isEmpty { break }
            
            let uTotal = uEnd.reduce(0) { $0 + Int($1.value) }
            let oTotal = oEnd.reduce(0) { $0 + Int($1.value) }
            
            if uTotal > oTotal { uPoints += 2 }
            else if oTotal > uTotal { oPoints += 2 }
            else if !uEnd.isEmpty { uPoints += 1; oPoints += 1 }
            
            if uPoints >= winningPoints || oPoints >= winningPoints {
                return min(i + 1, match.matchFormat.maxEnds)
            }
            
            minEnds = max(minEnds, i + 2)
        }
        return min(minEnds, match.matchFormat.maxEnds)
    }
}

struct H2HScoringView: View {
    @Bindable var match: HeadToHeadMatch
    
    let archerName: String?
    let archerCountry: String?
    
    @State private var activeIndex: H2HTargetEnd? = nil
    @State private var initialArcherForOverlay: H2HEndInputOverlayView.ActiveArcher = .user
    
    var matchFace: TargetFace {
        match.eliminationType.targetFaces.first ?? .xTenZone
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack {
                    Text("You").font(.headline)
                    Text("\(match.eliminationType.isCumulativeScoring ? match.userTotalScore : match.userSetPoints)")
                        .font(.system(size: 36, weight: .bold))
                }
                
                Spacer()
                
                Text(match.eliminationType.isCumulativeScoring ? "Total Score" : "Set Points")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack {
                    Text(match.opponentName.isEmpty ? "Opp." : match.opponentName).font(.headline)
                    Text("\(match.eliminationType.isCumulativeScoring ? match.opponentTotalScore : match.opponentSetPoints)")
                        .font(.system(size: 36, weight: .bold))
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            
            Divider()
            
            H2HScoresheetView(match: match, archerName: archerName, archerCountry: archerCountry) { index, activeArcher in
                initialArcherForOverlay = activeArcher
                activeIndex = index
            }
        }
        .navigationTitle(match.label)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: Binding(
            get: { activeIndex != nil },
            set: { if !$0 { activeIndex = nil } }
        )) {
            if let index = activeIndex {
                switch index {
                    case .regular(let idx):
                        H2HEndInputOverlayView(
                            match: match,
                            endIndex: Binding(
                                get: { idx },
                                set: { activeIndex = .regular($0) }
                            ),
                            face: matchFace,
                            initialArcher: initialArcherForOverlay
                        )
                    case .shootOff(let idx):
                        H2HShootOffInputOverlayView(
                            match: match,
                            shootOffIndex: Binding(
                                get: { idx },
                                set: { activeIndex = .shootOff($0) }
                            ),
                            face: matchFace,
                            initialArcher: initialArcherForOverlay
                        )
                }
            }
        }
    }
}

struct H2HEndInputOverlayView: View {
    @Bindable var match: HeadToHeadMatch
    @Binding var endIndex: Int
    let face: TargetFace
    
    @State private var scoringType = "Target Face"
    @State private var activeArcher: ActiveArcher
    @State private var selectedArrowSlot: Int = 0
    
    enum ActiveArcher: String, CaseIterable {
        case user = "You"
        case opponent = "Opponent"
    }
    
    var arrowsPerEnd: Int { match.matchFormat.arrowsPerEnd }
    
    var currentArrows: [ArrowScore] {
        activeArcher == .user ? match.userArrows[endIndex] : match.opponentArrows[endIndex]
    }
    
    init(match: HeadToHeadMatch, endIndex: Binding<Int>, face: TargetFace, initialArcher: ActiveArcher = .user) {
        self.match = match
        self._endIndex = endIndex
        self.face = face
        self._activeArcher = State(initialValue: initialArcher)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Archer", selection: $activeArcher) {
                ForEach(ActiveArcher.allCases, id: \.self) { archer in
                    Text(archer.rawValue).tag(archer)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            HStack(spacing: 8) {
                ForEach(0..<arrowsPerEnd, id: \.self) { slotIndex in
                    let arrowExists = slotIndex < currentArrows.count
                    let isSelected = slotIndex == selectedArrowSlot
                    
                    VStack {
                        Text("\(slotIndex + 1)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(arrowExists ? currentArrows[slotIndex].displayText : "")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, minHeight: 45)
                            .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                            )
                    }
                    .onTapGesture { selectedArrowSlot = slotIndex }
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
            .padding(.horizontal)
            .padding(.bottom)
            
            if activeArcher == .user {
                Picker("Input Mode", selection: $scoringType) {
                    Text("Target Face").tag("Target Face")
                    Text("Keypad").tag("Keypad")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
            
            Spacer()
            
            if scoringType == "Keypad" || activeArcher == .opponent {
                KeypadInputView(face: face) { value, isX in
                    saveArrowToSlot(ArrowScore(value: value, isX: isX))
                }
                .transition(.opacity)
            } else {
                InteractivePlottingFaceView(face: face, arrows: currentArrows) { value, isX, x, y in
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
                    Button(action: { if endIndex > 0 { endIndex = max(0, min(endIndex - 1, accessibleEnds(match: match) - 1)) } }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .foregroundColor(endIndex > 0 ? .blue : .gray.opacity(0.3))
                    }
                    .disabled(endIndex == 0)
                    
                    Text("End \(endIndex + 1)").font(.headline).frame(minWidth: 70)
                    
                    Button(action: { if endIndex < accessibleEnds(match: match) - 1 { endIndex += 1 } }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .foregroundColor(endIndex < accessibleEnds(match: match) - 1 ? .blue : .gray.opacity(0.3))
                    }
                    .disabled(endIndex == accessibleEnds(match: match) - 1)
                }
            }
        }
        .onAppear { autoFocusNextSlot() }
        .onChange(of: endIndex) { autoFocusNextSlot() }
        .onChange(of: activeArcher) { autoFocusNextSlot() }
    }
    
    private func autoFocusNextSlot() {
        selectedArrowSlot = currentArrows.count < arrowsPerEnd ? currentArrows.count : arrowsPerEnd - 1
    }
    
    private func saveArrowToSlot(_ arrow: ArrowScore) {
        var arrows = activeArcher == .user ? match.userArrows[endIndex] : match.opponentArrows[endIndex]
        
        if selectedArrowSlot < arrows.count {
            arrows[selectedArrowSlot] = arrow
        } else {
            while arrows.count < selectedArrowSlot {
                arrows.append(ArrowScore(value: 0))
            }
            arrows.append(arrow)
        }
        
        if activeArcher == .user {
            match.userArrows[endIndex] = arrows
        } else {
            match.opponentArrows[endIndex] = arrows
        }
        
        if selectedArrowSlot < arrowsPerEnd - 1 {
            selectedArrowSlot += 1
        } else {
            if activeArcher == .user {
                activeArcher = .opponent
                selectedArrowSlot = 0
            } else if endIndex < accessibleEnds(match: match) - 1 {
                    endIndex += 1
                    activeArcher = .user
                    selectedArrowSlot = 0
            }
        }
    }
    
    private func deleteSelectedOrPrevious() {
        var arrows = activeArcher == .user ? match.userArrows[endIndex] : match.opponentArrows[endIndex]
        
        if selectedArrowSlot < arrows.count {
            arrows.remove(at: selectedArrowSlot)
        } else if selectedArrowSlot > 0 {
            selectedArrowSlot -= 1
            if selectedArrowSlot < arrows.count {
                arrows.remove(at: selectedArrowSlot)
            }
        }
        
        if activeArcher == .user {
            match.userArrows[endIndex] = arrows
        } else {
            match.opponentArrows[endIndex] = arrows
        }
    }
}

struct H2HShootOffInputOverlayView: View {
    @Bindable var match: HeadToHeadMatch
    @Binding var shootOffIndex: Int
    let face: TargetFace
    
    @State private var scoringType = "Target Face"
    @State private var activeArcher: H2HEndInputOverlayView.ActiveArcher
    
    init(match: HeadToHeadMatch, shootOffIndex: Binding<Int>, face: TargetFace, initialArcher: H2HEndInputOverlayView.ActiveArcher = .user) {
        self.match = match
        self._shootOffIndex = shootOffIndex
        self.face = face
        self._activeArcher = State(initialValue: initialArcher)
    }
    
    var currentArrow: [ArrowScore] {
        let arrows = activeArcher == .user ? match.userShootOffs : match.opponentShootOffs
        if shootOffIndex < arrows.count {
            return [arrows[shootOffIndex]]
        }
        return []
    }
    
    var bothArchersShot: Bool {
        match.userShootOffs.count > shootOffIndex && match.opponentShootOffs.count > shootOffIndex
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            Picker("Archer", selection: $activeArcher) {
                Text("You").tag(H2HEndInputOverlayView.ActiveArcher.user)
                Text("Opponent").tag(H2HEndInputOverlayView.ActiveArcher.opponent)
            }
            .pickerStyle(.segmented)
            .padding()
            
            HStack {
                Text("Arrow 1")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(!currentArrow.isEmpty ? currentArrow[0].displayText : "")
                    .font(.title2.bold())
                    .frame(width: 80, height: 45)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))
                
                Button(action: deleteArrow) {
                    Image(systemName: "delete.left")
                        .font(.title2)
                        .frame(width: 45, height: 45)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
                .padding(.leading, 8)
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            if bothArchersShot && (match.userShootOffs[shootOffIndex].xCoordinate == nil || match.opponentShootOffs[shootOffIndex].xCoordinate == nil) {
                VStack(spacing: 8) {
                    Text("Resolution Override (If Tied)")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Button(action: { match.manualShootOffWinner = true }) {
                            Text("You Won")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(match.manualShootOffWinner == true ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(match.manualShootOffWinner == true ? .white : .primary)
                                .cornerRadius(8)
                        }
                        
                        Button(action: { match.manualShootOffWinner = nil }) {
                            Text("Unresolved")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(match.manualShootOffWinner == nil ? Color.orange : Color.gray.opacity(0.2))
                                .foregroundColor(match.manualShootOffWinner == nil ? .white : .primary)
                                .cornerRadius(8)
                        }
                        
                        Button(action: { match.manualShootOffWinner = false }) {
                            Text("Opp. Won")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(match.manualShootOffWinner == false ? Color.red : Color.gray.opacity(0.2))
                                .foregroundColor(match.manualShootOffWinner == false ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            
            Picker("Input Mode", selection: $scoringType) {
                Text("Target Face").tag("Target Face")
                Text("Keypad").tag("Keypad")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Spacer()
            
            if scoringType == "Keypad" {
                KeypadInputView(face: face) { value, isX in
                    saveArrow(ArrowScore(value: value, isX: isX))
                }
                .transition(.opacity)
            } else {
                InteractivePlottingFaceView(face: face, arrows: currentArrow) { value, isX, x, y in
                    saveArrow(ArrowScore(value: value, isX: isX, x: x, y: y))
                }
                .padding(.bottom, 20)
                .transition(.opacity)
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle("Shoot-off Arrow \(shootOffIndex + 1)")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func saveArrow(_ arrow: ArrowScore) {
        if activeArcher == .user {
            if shootOffIndex < match.userShootOffs.count {
                match.userShootOffs[shootOffIndex] = arrow
            } else {
                match.userShootOffs.append(arrow)
            }
            if match.opponentShootOffs.count <= shootOffIndex { activeArcher = .opponent }
        } else {
            if shootOffIndex < match.opponentShootOffs.count {
                match.opponentShootOffs[shootOffIndex] = arrow
            } else {
                match.opponentShootOffs.append(arrow)
            }
            if match.userShootOffs.count <= shootOffIndex { activeArcher = .user }
        }
    }
    
    private func deleteArrow() {
        if activeArcher == .user {
            if shootOffIndex < match.userShootOffs.count { match.userShootOffs.remove(at: shootOffIndex) }
        } else {
            if shootOffIndex < match.opponentShootOffs.count { match.opponentShootOffs.remove(at: shootOffIndex) }
        }
    }
}

#Preview {
    NavigationStack {
        H2HScoringView(match: HeadToHeadMatch(label: "Final", eliminationType: EliminationType.worldArchery.individual70m, opponentName: "Ki Bo Bae"),
                       archerName: "Chang Hye Jin",
                       archerCountry: "KOR - Korea"
        )
    }
}

