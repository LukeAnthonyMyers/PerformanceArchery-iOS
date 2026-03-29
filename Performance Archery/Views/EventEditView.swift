//
//  EventEditView.swift
//  Performance Archery
//
//  Created by Luke Myers on 27/04/2025.
//

import CoreLocation
import CoreLocationUI
import MapKit
import SwiftData
import SwiftUI

protocol Event {
    var startDate: Date { get set }
    var endDate: Date { get set }
    var goals: String { get set }
    var reflection: String { get set }
    var locationName: String { get set }
    var latitude: Double? { get set }
    var longitude: Double? { get set }
}

extension ShootingSession: Event {}
extension CoachingSession: Event {}
extension Competition: Event {}

struct EventEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var event: (any Event & AnyObject)?
    
    @StateObject private var viewModel = CompetitionViewModel()
    
    @State private var selectedStartDate: Date = Date()
    @State private var selectedEndDate: Date = Date()
    @State private var isMultiDay: Bool = false
    @State private var competitionName: String = ""
    @State private var coachName: String = ""
    @State private var cost: String = ""
    @State private var scores: [String] = [""]
    @State private var goals: String = ""
    @State private var reflection: String = ""
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.7276, longitude: -2.3719), // Lilleshall NSC
        span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
    )
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.7276, longitude: -2.3719),
            span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
    ))
    
    let sessionTypes = ["Training", "Coaching", "Competition"]
    @State private var selectedSessionType = "Training"
    
    let trainingTypes = ["Shooting", "SPT", "S&C"]
    @State private var selectedTrainingType = "Shooting"
    
    @State private var selectedRounds: [RoundType] = [RoundType.allRounds[0]]
    @State private var roundDayIndices: [Int] = [0]
    
    private var competitionDays: Int {
        if !isMultiDay { return 1 }
        let start = Calendar.current.startOfDay(for: selectedStartDate)
        let end = Calendar.current.startOfDay(for: selectedEndDate)
        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
        return max(1, days + 1)
    }
    
    init(event: (any Event & AnyObject)? = nil) {
        self.event = event
        
        if let event = event {
            _selectedStartDate = State(initialValue: event.startDate)
            _selectedEndDate = State(initialValue: event.endDate)
            _isMultiDay = State(initialValue: !Calendar.current.isDate(event.startDate, inSameDayAs: event.endDate))
            _address = State(initialValue: event.locationName)
            
            if let latitude = event.latitude, let longitude = event.longitude {
                _region = State(initialValue: MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), // Lilleshall NSC
                    span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
                ))
                _position = State(initialValue: .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                    span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
                )))
                _selectedCoordinate = State(initialValue: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
            
            if let competition = event as? Competition {
                _viewModel = StateObject(wrappedValue: CompetitionViewModel(competition: competition))
                
                _selectedSessionType = State(initialValue: "Competition")
                _competitionName = State(initialValue: competition.name)
                _cost = State(initialValue: String(competition.cost))
                _selectedRounds = State(initialValue: competition.rounds.isEmpty ? [RoundType.allRounds[0]] : competition.rounds.map { $0.roundType })
                _roundDayIndices = State(initialValue: competition.rounds.isEmpty ? [0] : competition.rounds.map { $0.index })
                _scores = State(initialValue: competition.rounds.isEmpty ? [""] : competition.rounds.map { String($0.score) })
                _goals = State(initialValue: competition.goals)
                _reflection = State(initialValue: competition.reflection)
            } else if let coachingSession = event as? CoachingSession {
                _selectedSessionType = State(initialValue: "Coaching")
                _coachName = State(initialValue: coachingSession.coachName)
                _goals = State(initialValue: coachingSession.goals)
                _reflection = State(initialValue: coachingSession.reflection)
            } else if let trainingSession = event as? ShootingSession {
                _selectedSessionType = State(initialValue: "Training")
                _goals = State(initialValue: trainingSession.goals)
                _reflection = State(initialValue: trainingSession.reflection)
            }
        }
    }

    private let currencySymbol = Locale.current.currencySymbol ?? "$"
    
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    
    @State private var address: String = ""

    var body: some View {
        Form {
            Picker("Select an event type", selection: $selectedSessionType) {
                ForEach(sessionTypes, id: \.self) { sessionType in
                    Text(sessionType)
                }
            }
            .pickerStyle(.segmented)
            .disabled(event != nil)
            
            if selectedSessionType == "Training" {
                Picker("Select a training type", selection: $selectedTrainingType) {
                    ForEach(trainingTypes, id: \.self) { trainingType in
                        Text(trainingType)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(event != nil)
            }
            
            if selectedSessionType == "Competition" {
                TextField("Competition name", text: $competitionName)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                
                HStack {
                    Text(currencySymbol)

                    TextField("Cost", text: $cost)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack {
                    Toggle("Set Entry Opening Time", isOn: $viewModel.entriesOpenEnabled)
                    
                    if viewModel.entriesOpenEnabled {
                        DatePicker(
                            "Entries Open",
                            selection: Binding(
                                get: { viewModel.entryOpeningTime ?? Date() },
                                set: { viewModel.entryOpeningTime = $0 }
                            )
                        )
                        
                        Toggle("Remind me when entries open", isOn: $viewModel.setReminder)
                            .onChange(of: viewModel.setReminder) { _, newValue in
                                if newValue {
                                    NotificationService.requestPermission { granted in
                                        if !granted {
                                            viewModel.setReminder = false
                                            print("User denied notification permission.")
                                        }
                                    }
                                }
                            }
                    }
                }
                
                VStack {
                    ForEach(0..<selectedRounds.count, id: \.self) { index in
                        VStack {
                            Picker("Round", selection: $selectedRounds[index]) {
                                Section(header: Text("World Archery")) {
                                    ForEach(RoundType.worldArchery, id: \.self) { round in
                                        Text(round.name).tag(round)
                                    }
                                }
                                Section(header: Text("Archery GB")) {
                                    ForEach(RoundType.archeryGB, id: \.self) { round in
                                        Text(round.name).tag(round)
                                    }
                                }
                            }
                            .pickerStyle(.menu)
                            
                            if isMultiDay {
                                Picker("Day", selection: $roundDayIndices[index]) {
                                    ForEach(0..<competitionDays, id: \.self) { day in
                                        if let date = Calendar.current.date(byAdding: .day, value: day, to: selectedStartDate) {
                                            Text(date.formatted(.dateTime.weekday(.wide)))
                                                .tag(day)
                                        }
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        
                        Divider()
                            .frame(height: 10)
                    }
                    
                    HStack {
                        if selectedRounds.count > 1 {
                            Button("Remove Round") {
                                selectedRounds.removeLast()
                                scores.removeLast()
                                roundDayIndices.removeLast()
                            }
                            
                            Divider()
                        }
                        
                        Button("Add Another Round") {
                            selectedRounds.append(RoundType.allRounds[0])
                            scores.append("")
                            roundDayIndices.append(0)
                        }
                    }
                    .buttonStyle(.borderless)
                }
                
                VStack {
                    ForEach(selectedRounds.indices, id: \.self) { index in
                        TextField(selectedRounds.count > 1 ? "Score - Round \(index + 1)" : "Score", text: $scores[index])
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            } else if selectedSessionType == "Coaching" {
                TextField("Coach", text: $coachName)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .textContentType(.name)
            }
            
            VStack {
                Toggle("Multiple Days", isOn: $isMultiDay)
                if isMultiDay {
                    DatePicker("\(selectedSessionType) Start Date", selection: $selectedStartDate, displayedComponents: .date)
                    if let earliestEndDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedStartDate) {
                        DatePicker(
                            "\(selectedSessionType) End Date",
                            selection: $selectedEndDate,
                            in: earliestEndDate...,
                            displayedComponents: .date
                        )
                    }
                } else {
                    DatePicker("Date of \(selectedSessionType)", selection: $selectedStartDate, displayedComponents: .date)
                }
            }
            
            VStack {
                HStack {
                    TextField("Location", text: $address, onCommit: {
                        searchForLocation()
                    })
                    .textFieldStyle(.roundedBorder)
                    
                    LocationButton(.currentLocation) {
                        requestCurrentLocation()
                    }
                    .labelStyle(.iconOnly)
                    .cornerRadius(10)
                }
                
                MapReader { proxy in
                    Map(position: $position) {
                        if let coord = selectedCoordinate {
                            Marker(address.components(separatedBy: ",").first ?? "", coordinate: coord).tint(.red)
                        }
                    }
                    .onTapGesture { position in
                        if let coordinate = proxy.convert(position, from: .local) {
                            selectedCoordinate = coordinate
                        }
                    }
                    .frame(height: 250)
                }
                .padding(5)
            }
            
            VStack {
                Text("Goals")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextEditor(text: $goals)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 1)
                    )
            }
            
            VStack {
                Text("Reflection")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextEditor(text: $reflection)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 1)
                    )
            }
            
            if event == nil {
                Button(action: {
                    createSession()
                }) {
                    Text("Add \(selectedSessionType)\(selectedSessionType == "Competition" ? "" : " session")")
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Button(action: {
                    updateSession()
                }) {
                    Text("Update \(selectedSessionType)\(selectedSessionType == "Competition" ? "" : " session")")
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: selectedStartDate) { _, newDate in
            if selectedEndDate < newDate { selectedEndDate = newDate }
        }
        .onChange(of: isMultiDay) {
            if isMultiDay {
                selectedEndDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedStartDate) ?? selectedStartDate
            }
        }
    }
    
    private func searchForLocation() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                return
            }
            if let placemark = placemarks?.first, let location = placemark.location {
                selectedCoordinate = location.coordinate
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                position = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
        }
    }
    
    private func updateSession() {
        guard var existingEvent = event else { return }

        existingEvent.startDate = selectedStartDate
        existingEvent.endDate = isMultiDay ? selectedEndDate : selectedStartDate
        existingEvent.goals = goals
        existingEvent.reflection = reflection
        existingEvent.locationName = address
        
        if let coord = selectedCoordinate {
            existingEvent.latitude = coord.latitude
            existingEvent.longitude = coord.longitude
        }

        if let competition = existingEvent as? Competition {
            competition.name = competitionName
            competition.cost = cost
            competition.entryOpeningTime = viewModel.entryOpeningTime

            let targetCount = selectedRounds.count
            
            while competition.rounds.count > targetCount {
                if let roundToRemove = competition.rounds.last {
                    modelContext.delete(roundToRemove)
                    competition.rounds.removeLast()
                }
            }
            
            if competition.rounds.count < targetCount {
                for i in competition.rounds.count..<targetCount {
                    competition.rounds.append(CompetitionRound(roundType: selectedRounds[i]))
                }
            }

            for i in 0..<targetCount {
                let round = competition.rounds[i]
                round.index = roundDayIndices[i]
                round.roundType = selectedRounds[i]
                if i < scores.count {
                    round.score = scores[i]
                }
            }

            viewModel.saveCompetition()
        } else if let coachingSession = existingEvent as? CoachingSession {
            coachingSession.coachName = coachName
        }

        try? modelContext.save()
        dismiss()
    }
    
    private func requestCurrentLocation() {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            if let location = locationManager.location?.coordinate {
                selectedCoordinate = location
                region = MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
        
        if let coord = selectedCoordinate {
            position = .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
    
    private func createSession() {
        withAnimation {
            switch selectedSessionType {
                case "Coaching":
                    let newItem = CoachingSession(startDate: selectedStartDate, endDate: selectedEndDate, multiDay: isMultiDay, coachName: coachName, goals: goals, reflection: reflection, locationName: address, location: selectedCoordinate)
                    modelContext.insert(newItem)
                case "Competition":
                    var newRounds: [CompetitionRound] = []
                    for i in 0..<selectedRounds.count {
                        let r = CompetitionRound(index: roundDayIndices[i], roundType: selectedRounds[i], score: i < scores.count ? scores[i] : "")
                        newRounds.append(r)
                    }
                    let newItem = Competition(isEntryReminderSet: viewModel.setReminder, entryOpeningTime: viewModel.entryOpeningTime, startDate: selectedStartDate, endDate: selectedEndDate, multiDay: isMultiDay, name: competitionName, cost: cost, rounds: newRounds, goals: goals, reflection: reflection, locationName: address, location: selectedCoordinate)
                        modelContext.insert(newItem)
                    
                        viewModel.competition = newItem
                        viewModel.saveCompetition()
                default:
                    let newItem = ShootingSession(startDate: selectedStartDate, endDate: selectedEndDate, multiDay: isMultiDay, goals: goals, reflection: reflection, locationName: address, location: selectedCoordinate)
                    modelContext.insert(newItem)
            }
            try? modelContext.save()
        }
        dismiss()
    }
}

#Preview {
    EventEditView()
        .modelContainer(for: [ShootingSession.self, CoachingSession.self, Competition.self], inMemory: true)
}

