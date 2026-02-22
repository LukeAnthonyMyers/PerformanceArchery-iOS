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
    @State private var viewModel: CompetitionViewModel
    
    init(competition: Competition) {
        self.competition = competition
        _viewModel = State(initialValue: CompetitionViewModel(competition: competition))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(competition.name)")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("\(competition.startDate.formatted(date: .complete, time: .omitted)) at \(competition.locationName)")
            Spacer()
            Divider()

            List {
                ForEach(viewModel.displayedSchedule, id: \.persistentModelID) { item in
                    ScheduleRowView(item: item, competition: competition, isRound: false)
                }
                .onDelete(perform: viewModel.deleteItems)
                .onMove(perform: viewModel.moveItems)

                ScheduleRowView(item: ScheduleItem(title: competition.rounds[0].roundType.name, index: 0), competition: competition, isRound: true)
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { isShowingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { viewModel.addScheduleItem() }) {
                        Image(systemName: "plus")
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
}

struct ScheduleRowView: View {
    @Bindable var item: ScheduleItem
    @Bindable var competition: Competition
    let isRound: Bool

    var body: some View {
        HStack(spacing: 15) {
            Rectangle()
                .fill(isRound ? .red.opacity(0.3) : .blue.opacity(0.3))
                .frame(width: 2)
            
            if isRound {
                HStack {
                    Text(item.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("Target assignment:")
                        .font(.subheadline)
                    
                    TextField("...", text: $competition.rounds[0].targetAssignment)
                        .font(.subheadline)
                        .frame(width: 30)
                }
            } else {
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
        }
        .listRowSeparator(.hidden)
    }
}

#Preview {
    let startDate: Date = {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 3
        comps.day = 26
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
        entryOpeningTime: Date(),
        startDate: startDate,
        endDate: endDate,
        multiDay: true,
        name: "The Vegas Shoot",
        cost: "200",
        rounds: [CompetitionRound(roundType: RoundType.archeryGB[3])],
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

