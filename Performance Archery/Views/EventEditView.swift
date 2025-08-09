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
    var dateTime: Date { get set }
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
    
    @State private var selectedDate: Date = Date()
    @State private var competitionName: String = ""
    @State private var coachName: String = ""
    @State private var cost: String = ""
    @State private var score: String = ""
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
    
    let rounds = ["WA18", "WA25", "WA720", "WA900", "WA1440"]
    @State private var selectedRound = "WA720"
    
    init(event: (any Event & AnyObject)? = nil) {
        self.event = event
        
        if let event = event {
            _selectedDate = State(initialValue: event.dateTime)
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
                _selectedSessionType = State(initialValue: "Competition")
                _competitionName = State(initialValue: competition.name)
                _cost = State(initialValue: String(competition.cost))
                _selectedRound = State(initialValue: String(competition.round))
                _score = State(initialValue: String(competition.score))
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
        } else {
            _selectedSessionType = State(initialValue: "Training")
        }
    }

    private let currencySymbol = Locale.current.currencySymbol ?? "$"
    
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    
    @State private var address: String = ""

    var body: some View {
        VStack {
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
                    
                    HStack {
                        Text(currencySymbol)

                        TextField("Cost", text: $cost)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Picker("Round", selection: $selectedRound) {
                        ForEach(rounds, id: \.self) { round in
                            Text(round)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    TextField("Score", text: $score)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                } else if selectedSessionType == "Coaching" {
                    TextField("Coach", text: $coachName)
                        .textFieldStyle(.roundedBorder)
                }
                
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                
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

        existingEvent.dateTime = selectedDate
        existingEvent.goals = goals
        existingEvent.reflection = reflection
        if let coord = selectedCoordinate {
            existingEvent.latitude = coord.latitude
            existingEvent.longitude = coord.longitude
        }

        if let competition = existingEvent as? Competition {
            competition.name = competitionName
            competition.cost = cost
            competition.round = selectedRound
            competition.score = score
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
                let newItem = CoachingSession(dateTime: selectedDate, coachName: coachName, goals: goals, reflection: reflection, locationName: address, location: selectedCoordinate)
                    modelContext.insert(newItem)
                case "Competition":
                let newItem = Competition(dateTime: selectedDate, name: competitionName, cost: cost, score: score, round: selectedRound, goals: goals, reflection: reflection, locationName: address, location: selectedCoordinate)
                    modelContext.insert(newItem)
                default:
                    let newItem = ShootingSession(dateTime: selectedDate, goals: goals, reflection: reflection, locationName: address, location: selectedCoordinate)
                    modelContext.insert(newItem)
            }
        }
        dismiss()
    }
}

#Preview {
    EventEditView()
        .modelContainer(for: [ShootingSession.self, CoachingSession.self, Competition.self], inMemory: true)
}
