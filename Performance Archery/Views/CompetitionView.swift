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
        VStack(alignment: .leading, spacing: 8) {
            Text("\(competition.name)")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(competition.dateTime.formatted(date: .complete, time: .omitted))

            List {
                ForEach(viewModel.displayedSchedule, id: \.persistentModelID) { item in
                    ScheduleRowView(item: item)
                }
                .onDelete(perform: viewModel.deleteItems)
                .onMove(perform: viewModel.moveItems)
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

    var body: some View {
        HStack(spacing: 15) {
            Rectangle()
                .fill(.blue.opacity(0.3))
                .frame(width: 2)

            TextField("...", text: $item.title, axis: .vertical)
                .font(.headline)
            
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

#Preview {
    let dummy = Competition(
        dateTime: Date(),
        name: "The Vegas Shoot",
        cost: "200",
        round: "WA18",
        goals: "Improve consistency",
        reflection: "Shot well",
        locationName: "Home",
        location: nil
    )

    NavigationStack {
        CompetitionView(competition: dummy)
    }
    .modelContainer(for: Competition.self, inMemory: true)
}

