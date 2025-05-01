//
//  EventCalendarView.swift
//  Performance Archery
//
//  Created by Luke Myers on 05/01/2025.
//

import SwiftUI
import SwiftData

struct AnyEvent: Identifiable {
    let id: UUID
    let dateTime: Date
    let type: CalendarView.EventType
    let base: Any

    init(_ training: TrainingSession) {
        self.id = training.id
        self.dateTime = training.dateTime
        self.type = .training
        self.base = training
    }

    init(_ coaching: CoachingSession) {
        self.id = coaching.id
        self.dateTime = coaching.dateTime
        self.type = .coaching
        self.base = coaching
    }

    init(_ competition: Competition) {
        self.id = competition.id
        self.dateTime = competition.dateTime
        self.type = .competitions
        self.base = competition
    }
}

struct CalendarView: View {
    struct EventCategory: Identifiable {
        let id = UUID()
        let type: EventType
        var show: Bool
    }
    
    enum EventType: String, CaseIterable, Identifiable {
        case training = "Training"
        case coaching = "Coaching"
        case competitions = "Competitions"

        var id: Self { self }

        var categoryName: String {
            rawValue
        }
        
        var displayName: String {
            switch self {
            case .training: return "Training Session"
            case .coaching: return "Coaching Session"
            case .competitions: return "Competition"
            }
        }
        
        var colour: Color {
            switch self {
            case .training: return Color(red: 0.64, green: 0.79, blue: 0.98)
            case .coaching: return Color(red: 0.70, green: 0.95, blue: 0.73)
            case .competitions: return Color(red: 1.0, green: 0.70, blue: 0.67)
            }
        }
    }
    
    var combinedEvents: [AnyEvent] {
        let allEvents: [AnyEvent] =
            trainingSessions.map(AnyEvent.init) +
            coachingSessions.map(AnyEvent.init) +
            competitions.map(AnyEvent.init)
        
        return allEvents
            .filter { isEventTypeVisible($0.type) }
            .sorted { $0.dateTime < $1.dateTime }
    }

    @State private var eventTypes = EventType.allCases.map { EventCategory(type: $0, show: true) }

    @State private var creatingEvent: Bool = false

    @Environment(\.modelContext) private var modelContext
    @Query private var coachingSessions: [CoachingSession]
    @Query private var competitions: [Competition]
    @Query private var trainingSessions: [TrainingSession]

    var body: some View {
        VStack {
            HStack {
                ForEach($eventTypes) { $eventType in
                    Spacer()
                    
                    HStack {
                        Text(eventType.type.categoryName)
                            .font(.system(size: 15))
                        ZStack {
                            Circle()
                                .fill(eventType.show ? eventType.type.colour : Color.gray.opacity(0.2))
                                .frame(width: 25, height: 25)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                            
                            Image(systemName: "checkmark")
                                .resizable()
                                .frame(width: 12, height: 12)
                                .foregroundColor(.white)
                                .scaleEffect(eventType.show ? 1 : 0)
                                .opacity(eventType.show ? 1 : 0)
                        }
                        .animation(.spring(response: 0.2), value: eventType.show)
                        .onTapGesture {
                            eventType.show.toggle()
                        }
                    }
                    
                    Spacer()
                }
            }
            
            Spacer(minLength: 25)
            
            NavigationSplitView {
                List {
                    Section(header: Text("All Events")) {
                        ForEach(combinedEvents) { event in
                            NavigationLink {
                                if let training = event.base as? TrainingSession {
                                    EventEditView(event: training)
                                } else if let coaching = event.base as? CoachingSession {
                                    EventEditView(event: coaching)
                                } else if let competition = event.base as? Competition {
                                    EventEditView(event: competition)
                                }
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(event.type.colour)
                                        .frame(width: 10, height: 10)
                                    Text(event.dateTime, format: Date.FormatStyle(date: .long))
                                    Spacer()
                                    Text(event.type.displayName)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .onDelete(perform: deleteEvents)
                    }
                }
                .offset(y: -30)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: {
                            creatingEvent = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $creatingEvent) {
                    EventEditView()
                }
                .navigationTitle("Calendar")
                .navigationBarTitleDisplayMode(.inline)
            } detail: {
                Text("Select an item")
            }
        }
    }
    
    private func deleteEvents(at offsets: IndexSet) {
        for index in offsets {
            let event = combinedEvents[index]
            switch event.type {
            case .training:
                if let training = event.base as? TrainingSession {
                    modelContext.delete(training)
                }
            case .coaching:
                if let coaching = event.base as? CoachingSession {
                    modelContext.delete(coaching)
                }
            case .competitions:
                if let competition = event.base as? Competition {
                    modelContext.delete(competition)
                }
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save model context after deletion: \(error)")
        }
    }
    
    func isEventTypeVisible(_ type: EventType) -> Bool {
        eventTypes.first(where: { $0.type == type })?.show ?? false
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [TrainingSession.self, CoachingSession.self, Competition.self], inMemory: true)
}
