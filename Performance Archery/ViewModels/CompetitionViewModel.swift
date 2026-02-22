//
//  CompetitionViewModel.swift
//  Performance Archery
//
//  Created by Luke Myers on 01/02/2026.
//

import SwiftData
import SwiftUI

class CompetitionViewModel: ObservableObject {
    @Published var competitionName: String = ""
    @Published var entryOpeningTime: Date? = nil
    @Published var setReminder: Bool = false
    @Published var entriesOpenEnabled: Bool = false {
        didSet {
            if !entriesOpenEnabled {
                entryOpeningTime = nil
                setReminder = false
            }
        }
    }
    
    var competition: Competition?

    init(competition: Competition? = nil) {
        self.competition = competition
        
        if let competition = competition {
            self.competitionName = competition.name
            self.entryOpeningTime = competition.entryOpeningTime
            self.entriesOpenEnabled = competition.entryOpeningTime != nil
            self.setReminder = competition.isEntryReminderSet
        }
    }

    var displayedSchedule: [ScheduleItem] {
        competition?.schedule.sorted { $0.index < $1.index } ?? []
    }

    func addScheduleItem() {
        guard let competition = competition else { return }
        let newItem = ScheduleItem(title: "", index: competition.schedule.count)
        competition.schedule.append(newItem)
    }

    func deleteItems(at offsets: IndexSet) {
        guard let competition = competition else { return }
        let displayed = displayedSchedule
        let itemsToDelete = offsets.map { displayed[$0] }
        for item in itemsToDelete {
            if let idx = competition.schedule.firstIndex(where: { $0.persistentModelID == item.persistentModelID }) {
                competition.schedule.remove(at: idx)
            }
        }
        reindexFromDisplayedOrder()
    }

    func moveItems(from source: IndexSet, to destination: Int) {
        guard let competition = competition else { return }
        var ids = displayedSchedule.map(\.persistentModelID)
        ids.move(fromOffsets: source, toOffset: destination)
        for (i, id) in ids.enumerated() {
            if let item = competition.schedule.first(where: { $0.persistentModelID == id }) {
                item.index = i
            }
        }
    }

    private func reindexFromDisplayedOrder() {
        for (i, item) in displayedSchedule.enumerated() {
            item.index = i
        }
    }
    
    func saveCompetition() {
        guard let competition = competition else { return }
        
        competition.isEntryReminderSet = setReminder
        
        if entriesOpenEnabled && setReminder {
            guard let entryOpeningTime = competition.entryOpeningTime else { return }
                    
            NotificationService.scheduleReminder(
                for: entryOpeningTime,
                competition: competition
            )
        } else {
            NotificationService.cancelReminder(for: competition)
        }
    }
}
