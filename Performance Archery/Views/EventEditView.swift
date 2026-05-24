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
    var notes: AttributedString { get set }
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
    @Environment(\.fontResolutionContext) private var fontResolutionContext

    var event: (any Event & AnyObject)?
    
    @StateObject private var viewModel = CompetitionViewModel()
    
    @State private var selectedStartDate: Date = Date()
    @State private var selectedEndDate: Date = Date()
    @State private var isMultiDay: Bool = false
    @State private var isConfirmed: Bool = true
    @State private var competitionName: String = ""
    @State private var coachName: String = ""
    @State private var cost: String = ""
    @State private var scores: [String] = [""]
    @State private var notesModel = RichTextEditorModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.7276, longitude: -2.3719), // Lilleshall NSC
        span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
    )
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.7276, longitude: -2.3719),
            span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
    ))
        
    @State private var currentFontSize: CGFloat = 17.0
    
    let sessionTypes = ["Training", "Coaching", "Competition"]
    @State private var selectedSessionType = "Training"
    
    let trainingTypes = ["Shooting", "SPT", "S&C"]
    @State private var selectedTrainingType = "Shooting"
    
    @State private var selectedRounds: [RoundType] = [RoundType.allRounds[0]]
    @State private var roundDayIndices: [UInt] = [0]
    
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
            _notesModel = State(initialValue: RichTextEditorModel(text: event.notes))
            
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
                let competitionRounds = competition.stages.compactMap { $0 as? CompetitionRound }
                
                _viewModel = StateObject(wrappedValue: CompetitionViewModel(competition: competition))
                
                _selectedSessionType = State(initialValue: "Competition")
                _competitionName = State(initialValue: competition.name)
                _isConfirmed = State(initialValue: competition.isConfirmed)
                _cost = State(initialValue: String(competition.cost))
                _selectedRounds = State(initialValue: competitionRounds.isEmpty ? [RoundType.allRounds[0]] : competitionRounds.map { $0.roundType })
                _roundDayIndices = State(initialValue: competitionRounds.isEmpty ? [0] : competitionRounds.map { $0.dayIndex })
                _scores = State(initialValue: competitionRounds.isEmpty ? [""] : competitionRounds.map { String($0.score) })
            } else if let coachingSession = event as? CoachingSession {
                _selectedSessionType = State(initialValue: "Coaching")
                _coachName = State(initialValue: coachingSession.coachName)
            } else if event is ShootingSession {
                _selectedSessionType = State(initialValue: "Training")
            }
        }
    }

    private let currencySymbol = Locale.current.currencySymbol ?? "$"
    
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    
    @State private var address: String = ""
    
    @FocusState private var isEditorFocused: Bool
    @State private var showFormatSheet = false

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
                    Toggle("Confirmed", isOn: $isConfirmed)
                    
                    if !isConfirmed {
                        Toggle("Set Entry Opening Time", isOn: $viewModel.entriesOpenEnabled)
                        
                        if viewModel.entriesOpenEnabled {
                            DatePicker(
                                "Entries Open",
                                selection: Binding(
                                    get: { viewModel.entryOpeningTime ?? Date() },
                                    set: { viewModel.entryOpeningTime = $0 }
                                )
                            )
                            
                            Toggle("Set Reminder", isOn: $viewModel.setReminder)
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
                                                .tag(UInt(day))
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
                Text("Notes")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextEditor(text: $notesModel.text, selection: $notesModel.selection)
                    .focused($isEditorFocused)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Button {
                                isEditorFocused = false
                                showFormatSheet = true
                            } label: {
                                Image(systemName: "textformat")
                            }
                            
                            Button {
                                notesModel.toggleBold(context: fontResolutionContext)
                            } label: {
                                Image(systemName: "bold")
                            }
                            .foregroundStyle(notesModel.isBold(context: fontResolutionContext) ? .blue : .primary)
                            
                            Button {
                                notesModel.toggleItalic(context: fontResolutionContext)
                            } label: {
                                Image(systemName: "italic")
                            }
                            .foregroundStyle(notesModel.isItalic(context: fontResolutionContext) ? .blue : .primary)
                            
                            Button {
                                notesModel.toggleUnderline()
                            } label: {
                                Image(systemName: "underline")
                            }
                            .foregroundStyle(notesModel.isUnderlined ? .blue : .primary)
                        }
                    }
            }
            .sheet(isPresented: $showFormatSheet) {
                FormattingSheetView(notesModel: notesModel, context: fontResolutionContext) {
                    isEditorFocused = true
                }
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.visible)
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
            if isMultiDay {
                if let minEnd = Calendar.current.date(byAdding: .day, value: 1, to: newDate),
                   selectedEndDate < minEnd {
                    selectedEndDate = minEnd
                }
            } else {
                if selectedEndDate < newDate { selectedEndDate = newDate }
            }
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
        existingEvent.notes = notesModel.text
        existingEvent.locationName = address
        
        if let coord = selectedCoordinate {
            existingEvent.latitude = coord.latitude
            existingEvent.longitude = coord.longitude
        }

        if let competition = existingEvent as? Competition {
            competition.name = competitionName
            competition.cost = cost
            competition.entryOpeningTime = viewModel.entryOpeningTime
            competition.isConfirmed = isConfirmed

            let targetCount = selectedRounds.count
            
            while competition.stages.count > targetCount {
                if let stageToRemove = competition.stages.last {
                    modelContext.delete(stageToRemove)
                    competition.stages.removeLast()
                }
            }
            
            if competition.stages.count < targetCount {
                for i in competition.stages.count..<targetCount {
                    competition.stages.append(CompetitionRound(roundType: selectedRounds[i]))
                }
            }

            let rounds = competition.stages.compactMap { $0 as? CompetitionRound }

            for i in 0..<min(rounds.count, targetCount) {
                let round = rounds[i]
                round.dayIndex = roundDayIndices[i]
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
                let newItem = CoachingSession(startDate: selectedStartDate, endDate: selectedEndDate, multiDay: isMultiDay, coachName: coachName, notes: notesModel.text, locationName: address, location: selectedCoordinate)
                    modelContext.insert(newItem)
                case "Competition":
                    var newRounds: [CompetitionRound] = []
                    for i in 0..<selectedRounds.count {
                        let r = CompetitionRound(dayIndex: roundDayIndices[i], roundType: selectedRounds[i], score: i < scores.count ? scores[i] : "")
                        newRounds.append(r)
                    }
                let newItem = Competition(isConfirmed: isConfirmed, isEntryReminderSet: viewModel.setReminder, entryOpeningTime: viewModel.entryOpeningTime, startDate: selectedStartDate, endDate: selectedEndDate, multiDay: isMultiDay, name: competitionName, cost: cost, stages: newRounds, notes: notesModel.text, locationName: address, location: selectedCoordinate)
                        modelContext.insert(newItem)
                    
                        viewModel.competition = newItem
                        viewModel.saveCompetition()
                default:
                    let newItem = ShootingSession(startDate: selectedStartDate, endDate: selectedEndDate, multiDay: isMultiDay, notes: notesModel.text, locationName: address, location: selectedCoordinate)
                    modelContext.insert(newItem)
            }
            try? modelContext.save()
        }
        dismiss()
    }
}

struct FormattingSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let notesModel: RichTextEditorModel
    let context: SwiftUI.Font.Context
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        styleButton("Title", style: .title)
                        styleButton("Heading", style: .heading)
                        styleButton("Subheading", style: .subheading)
                        styleButton("Body", style: .body)
                    }
                    .padding(.horizontal)
                }

                Divider()

                HStack {
                    designButton("Default", design: .default)
                    Spacer()
                    designButton("Serif", design: .serif)
                    Spacer()
                    designButton("Mono", design: .monospaced)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Format")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.gray)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
    }

    private func styleButton(_ label: String, style: RichTextEditorModel.TextStyle) -> some View {
        let isSelected: Bool
        var buttonFont: Font
        
        switch style {
            case .title:
                isSelected = notesModel.currentFontSize == 28
                buttonFont = .system(size: 28, weight: .bold)
            case .heading:
                isSelected = notesModel.currentFontSize == 22
                buttonFont = .system(size: 22, weight: .semibold)
            case .subheading:
                isSelected = notesModel.currentFontSize == 19
                buttonFont = .system(size: 19, weight: .semibold)
            case .body:
                isSelected = notesModel.currentFontSize == 17
                buttonFont = .system(size: 17)
        }
        
        return Button(action: { notesModel.setTextStyle(style, context: context) }) {
            Text(label)
                .font(buttonFont)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
                .foregroundColor(isSelected ? .blue : .primary)
                .cornerRadius(10)
        }
    }
    
    private func designButton(_ label: String, design: Font.Design) -> some View {
        let isSelected = notesModel.currentDesign == design
        return Button(action: { notesModel.setDesign(design, context: context) }) {
            Text(label)
                .font(.subheadline)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
                .foregroundColor(isSelected ? .blue : .primary)
                .cornerRadius(10)
        }
    }
}

#Preview {
    EventEditView()
        .modelContainer(for: [ShootingSession.self, CoachingSession.self, Competition.self], inMemory: true)
}

