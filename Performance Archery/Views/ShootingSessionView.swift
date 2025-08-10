//
//  ShootingSessionView.swift
//  Performance Archery
//
//  Created by Luke Myers on 16/05/2025.
//

import CoreLocation
import SwiftUI

struct ShootingSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var session: ShootingSession
    
    @State private var addingShootingPeriod: Bool = false
    
    let shootingTypes = ["Competition Round", "Fixed Distance"]
    @State private var selectedShootingType = "Competition Round"
    
    let rounds = ["WA18", "WA25", "WA720", "WA900", "WA1440"]
    @State private var selectedRound = "WA720"
    
    @State private var startTime = Date()
    @State private var endTime = Date()
    
    @State private var selectedDate: Date = Date()
    @State private var goals: String = ""
    @State private var reflection: String = ""
    @State private var address: String = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil
    
    enum ShootingDistance: String, Codable, CaseIterable, Identifiable {
        case _15m = "15 m"
        case _18m = "18 m"
        case _20m = "20 m"
        case _25m = "25 m"
        case _30m = "30 m"
        case _40m = "40 m"
        case _50m = "50 m"
        case _60m = "60 m"
        case _70m = "70 m"
        case _90m = "90 m"
        case _110m = "110 m"
        case _120m = "120 m"
        case _145m = "145 m"
        case _165m = "165 m"
        case _185m = "185 m"
        case _10yds = "10 yds"
        case _20yds = "20 yds"
        case _25yds = "25 yds"
        case _30yds = "30 yds"
        case _40yds = "40 yds"
        case _50yds = "50 yds"
        case _60yds = "60 yds"
        case _80yds = "80 yds"
        case _100yds = "100 yds"
        case _120yds = "120 yds"
        case _140yds = "140 yds"
        case _180yds = "180 yds"

        var id: String { rawValue }
        var num: UInt8 {
            let digits = rawValue.prefix { $0.isNumber || $0 == " " }
            return UInt8(digits.trimmingCharacters(in: .whitespaces)) ?? 0
        }
        var isMetric: Bool {
            rawValue.contains("m")
        }
        var isClout: Bool {
            switch self {
                case ._120m, ._145m, ._165m, ._185m, ._80yds, ._100yds, ._120yds, ._140yds, ._180yds:
                    return true
                default:
                    return false
            }
        }
        var isTarget: Bool {
            switch self {
            case ._110m, ._120m, ._145m, ._165m, ._185m, ._120yds, ._140yds, ._180yds:
                    return false
                default:
                    return true
            }
        }
    }
    @State private var selectedDistance: ShootingDistance = ._70m
    
    enum Target: String, Codable, CaseIterable, Identifiable {
        enum Discipline: String, Codable {
            case target
            case hitMiss
            case field
            case clout
            case animal
            case none
        }

        case noFace = "No target face"
        case target16in = "16 inches"
        case target40cm = "40cm"
        case target60cm = "60cm"
        case target80cm = "80cm"
        case target122cm = "122cm"
        case hitMiss40mm = "40mm Hit/Miss"
        case hitMiss60mm = "60mm Hit/Miss"

        var id: String { rawValue }
        var type: Discipline {
            switch self {
            case .target16in, .target40cm, .target60cm, .target80cm, .target122cm:
                return .target
            case .hitMiss40mm, .hitMiss60mm:
                return .hitMiss
            case .noFace:
                return .none
            }
        }
    }
    @State private var selectedTarget: Target = .target122cm
    
    enum ShootingPeriod: Identifiable, Hashable {
        case fixedDistance(FixedDistanceShooting)
        case competitionRound(CompetitionRound)
        
        var id: UUID {
            switch self {
                case .fixedDistance(let fd): return fd.id
                case .competitionRound(let cr): return cr.id
            }
        }
        
        var startTime: Date {
            switch self {
                case .fixedDistance(let fd): return fd.startTime
                case .competitionRound(let cr): return cr.startTime
            }
        }
    }
    
    var combinedShootingPeriods: [ShootingPeriod] {
        let fixed = session.fixedDistanceShooting.map(ShootingPeriod.fixedDistance)
        let rounds = session.CompetitionRounds.map(ShootingPeriod.competitionRound)
        return (fixed + rounds).sorted { $0.startTime < $1.startTime }
    }

    var body: some View {
        List {
            ForEach(combinedShootingPeriods, id: \.id) { item in
                NavigationLink(value: item) {
                    switch item {
                        case .fixedDistance(let fd):
                            Text(fd.startTime.formatted(date: .omitted, time: .shortened)).bold()
                            Text("\(fd.targetFace) @ \(fd.distance)\(fd.metric ? "m" : "yds")")
                        case .competitionRound(let cr):
                            Text(cr.startTime.formatted(date: .omitted, time: .shortened)).bold()
                            Text("\(cr.name)")
                    }
                }
            }
        }
        .navigationDestination(for: ShootingPeriod.self) { item in
            switch item {
                case .fixedDistance(let fd):
                    Spacer()
                    HStack(spacing: 50) {
                        VStack {
                            Text("Shots\n\(fd.arrowCount)").font(.system(size: 30))
                                .multilineTextAlignment(.center)
                            Button("Increment", systemImage: "plus") {
                                fd.arrowCount += 1
                                try? modelContext.save()
                            }
                            Button("Decrement", systemImage: "minus") {
                                if fd.arrowCount > 0 { fd.arrowCount -= 1 }
                                try? modelContext.save()
                            }
                        }
                        VStack {
                            Text("Come Downs\n\(fd.comeDowns)").font(.system(size: 30))
                                .multilineTextAlignment(.center)
                            Button("Increment", systemImage: "plus") {
                                fd.comeDowns += 1
                                try? modelContext.save()
                            }
                            Button("Decrement", systemImage: "minus") {
                                if fd.comeDowns > 0 { fd.comeDowns -= 1 }
                                try? modelContext.save()
                            }
                        }
                    }
                    Spacer()
                case .competitionRound(let cr):
                    Text("\(cr.name)")
            }
        }
        .toolbar {
            ToolbarItem() {
                Button(action: {
                    addingShootingPeriod = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $addingShootingPeriod) {
            VStack {
                Picker("Select a shooting type", selection: $selectedShootingType) {
                    ForEach(shootingTypes, id: \.self) { shootingType in
                        Text(shootingType)
                    }
                }
                .pickerStyle(.segmented)
                
                if selectedShootingType == "Fixed Distance" {
                    HStack {
                        Picker("Target", selection: $selectedTarget) {
                            ForEach(Target.allCases) { target in
                                Text(target.rawValue).tag(target)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Picker("Distance", selection: $selectedDistance) {
                            Section(header: Text("Metric")) {
                                ForEach(ShootingDistance.allCases.filter { $0.isMetric }) { distance in
                                    Text(distance.rawValue).tag(distance)
                                }
                            }
                            
                            Section(header: Text("Imperial")) {
                                ForEach(ShootingDistance.allCases.filter { !$0.isMetric }) { distance in
                                    Text(distance.rawValue).tag(distance)
                                }
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } else {
                    Picker("Round", selection: $selectedRound) {
                        ForEach(rounds, id: \.self) { round in
                            Text(round)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                DatePicker(
                    "Start Time",
                    selection: $startTime,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                
                Button("Add Session") {
                    createSession()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("\(session.dateTime, format: Date.FormatStyle(date: .complete, time: .omitted))")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func createSession() {
        withAnimation {
            switch selectedShootingType {
                case "Fixed Distance":
                    let newItem = FixedDistanceShooting(distance: selectedDistance.num, metric: selectedDistance.isMetric, targetFace: selectedTarget.id, startTime: startTime)
                    session.fixedDistanceShooting.append(newItem)
                case "Competition Round":
                    let newItem = CompetitionRound(
                        name: selectedRound,
                        distances: [selectedDistance.num],
                        metric: selectedDistance.isMetric,
                        startTime: startTime,
                        targetFaces: [selectedTarget.id]
                    )
                    session.CompetitionRounds.append(newItem)
                default:
                    let newItem = ShootingSession(dateTime: selectedDate, goals: goals, reflection: reflection, locationName: address, location: selectedCoordinate)
                    modelContext.insert(newItem)
            }
            try? modelContext.save()
        }
        addingShootingPeriod = false
    }
}

#Preview {
    let dummy = ShootingSession(
        dateTime: Date(),
        goals: "Improve consistency",
        reflection: "Shot well",
        locationName: "Home",
        location: nil
    )

    NavigationStack {
            ShootingSessionView(session: dummy)
    }
    .modelContainer(for: ShootingSession.self, inMemory: true)
}
