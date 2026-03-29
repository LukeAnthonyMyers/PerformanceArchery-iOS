//
//  CompetitionView.swift
//  Performance Archery
//
//  Created by Luke Myers on 01/02/2026.
//

import SwiftData
import SwiftUI

struct CompetitionView: View {
    @Bindable var competition: Competition
    @Environment(\.modelContext) private var modelContext
    
    @State private var isShowingSettings = false
    @StateObject private var viewModel: CompetitionViewModel
    
    init(competition: Competition) {
        self.competition = competition
        _viewModel = StateObject(wrappedValue: CompetitionViewModel(competition: competition))
    }
    
    private var competitionDays: Int {
        if Calendar.current.isDate(competition.startDate, inSameDayAs: competition.endDate) { return 1 }
        let start = Calendar.current.startOfDay(for: competition.startDate)
        let end = Calendar.current.startOfDay(for: competition.endDate)
        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
        return max(1, days + 1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(competition.name)")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if Calendar.current.isDate(competition.startDate, inSameDayAs: competition.endDate) {
                Text("\(competition.startDate.formatted(date: .complete, time: .omitted))" + (competition.locationName.isEmpty ? "" : " at \(competition.locationName)"))
            } else {
                Text("\(competition.startDate.formatted(date: .complete, time: .omitted)) to \(competition.endDate.formatted(date: .complete, time: .omitted))" + (competition.locationName.isEmpty ? "" : " at \(competition.locationName)"))
            }
            Spacer()
            Divider()

            List {
                ForEach(0..<competitionDays, id: \.self) { dayIndex in
                    let dayDate = Calendar.current.date(byAdding: .day, value: dayIndex, to: competition.startDate) ?? competition.startDate
                    
                    Section {
                        let combinedItems = viewModel.itemsForDay(index: dayIndex, date: dayDate)
                        
                        ForEach(combinedItems) { rowItem in
                            switch rowItem {
                            case .schedule(let item):
                                ScheduleRowView(item: item)
                            case .round(let round):
                                RoundRowView(round: round)
                            }
                        }
                        .onMove { source, destination in
                            viewModel.moveItems(in: dayIndex, date: dayDate, from: source, to: destination)
                        }
                        .onDelete { offsets in
                            let itemsAtOffsets = offsets.map { combinedItems[$0] }
                            
                            let scheduleItemsToDelete = itemsAtOffsets.compactMap { item -> ScheduleItem? in
                                if case .schedule(let s) = item { return s }
                                return nil
                            }
                            
                            viewModel.deleteSpecificItems(scheduleItemsToDelete)
                        }
                    } header: {
                        if !Calendar.current.isDate(competition.startDate, inSameDayAs: competition.endDate) {
                            HStack {
                                Text("Day \(dayIndex + 1) - \(dayDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: { viewModel.addScheduleItem(for: dayDate) }) {
                                    Image(systemName: "plus")
                                        .font(.title3)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { isShowingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
                if Calendar.current.isDate(competition.startDate, inSameDayAs: competition.endDate) {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { viewModel.addScheduleItem(for: competition.startDate) }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
        }
        .padding()
        .sheet(isPresented: $isShowingSettings) {
            EventEditView(event: competition)
        }
    }
    
    private func deleteDailyItems(at offsets: IndexSet, from dailyItems: [ScheduleItem]) {
        let itemsToDelete = offsets.map { dailyItems[$0] }
        for item in itemsToDelete {
            if let idx = competition.schedule.firstIndex(where: { $0.persistentModelID == item.persistentModelID }) {
                competition.schedule.remove(at: idx)
            }
        }
    }
}

struct ScheduleRowView: View {
    @Bindable var item: ScheduleItem

    var body: some View {
        HStack(spacing: 15) {
            Rectangle()
                .fill(.blue.opacity(0.3))
                .frame(width: 2)
            
            TextField("...", text: $item.title, axis: .vertical)
                .font(.body)
            
            Spacer()
            
            DatePicker(
                "Select Time",
                selection: Binding<Date>(
                    get: { item.dateTime ?? Date() },
                    set: { item.dateTime = $0 }
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
        }
        .listRowSeparator(.hidden)
    }
}

struct RoundRowView: View {
    @Bindable var round: CompetitionRound

    var body: some View {
        HStack(spacing: 15) {
            Rectangle()
                .fill(.red.opacity(0.3))
                .frame(width: 2)
            
            Text(round.roundType.name)
                .font(.headline)
            
            Spacer()
            
            Text("Target assignment:")
                .font(.subheadline)
            
            TextField("...", text: $round.targetAssignment)
                .font(.subheadline)
                .frame(width: 30)
        }
        .listRowSeparator(.hidden)
    }
}

#Preview {
    let startDate: Date = {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 3
        comps.day = 27
        return Calendar.current.date(from: comps) ?? Date()
    }()
    
    let endDate: Date = {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 3
        comps.day = 29
        return Calendar.current.date(from: comps) ?? Date()
    }()
    
    let dummy = Competition(
        isEntryReminderSet: false,
        startDate: startDate,
        endDate: endDate,
        multiDay: true,
        name: "The Vegas Shoot",
        cost: "200",
        rounds: Array(repeating: CompetitionRound(roundType: RoundType.archeryGB[3]), count: 3),
        goals: "Improve consistency",
        reflection: "Shot well",
        locationName: "Las Vegas, Nevada",
        location: nil,
    )

    NavigationStack {
        CompetitionView(competition: dummy)
    }
    .modelContainer(for: Competition.self, inMemory: true)
}
