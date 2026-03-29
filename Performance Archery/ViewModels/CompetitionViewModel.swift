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

    func addScheduleItem(for date: Date) {
        guard let competition = competition else { return }
        let maxIndex = competition.schedule.map { $0.index }.max() ?? 0
        let newItem = ScheduleItem(title: "", dateTime: date, index: maxIndex + 1)
        competition.schedule.append(newItem)
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
    
    enum DayRowItem: Identifiable, Hashable {
        case schedule(ScheduleItem)
        case round(CompetitionRound)
        
        var id: ObjectIdentifier {
            switch self {
                case .schedule(let item): return ObjectIdentifier(item)
                case .round(let round): return ObjectIdentifier(round)
            }
        }
        
        var sortOrder: Int {
            switch self {
                case .schedule(let item): return item.index
                case .round(let round): return round.sortIndex
            }
        }
    }
    
    func itemsForDay(index: Int, date: Date) -> [DayRowItem] {
        let dayItems = competition?.schedule.filter {
            Calendar.current.isDate($0.dateTime ?? date, inSameDayAs: date)
        }.map { DayRowItem.schedule($0) } ?? []
        
        let dayRounds = competition?.rounds.filter { round in
            if let roundDate = round.startTime {
                return Calendar.current.isDate(roundDate, inSameDayAs: date)
            }
            return round.index == index
        }.map { DayRowItem.round($0) } ?? []
        
        return (dayItems + dayRounds).sorted { item1, item2 in
            if item1.sortOrder == item2.sortOrder {
                if case .round = item1 { return true }
                if case .round = item2 { return false }
            }
            return item1.sortOrder < item2.sortOrder
        }
    }

    func moveItems(in dayIndex: Int, date: Date, from source: IndexSet, to destination: Int) {
        var items = itemsForDay(index: dayIndex, date: date)
        items.move(fromOffsets: source, toOffset: destination)
        
        for (newIndex, item) in items.enumerated() {
            switch item {
            case .schedule(let s): s.index = newIndex
            case .round(let r): r.sortIndex = newIndex
            }
        }
        
        self.objectWillChange.send()
    }
    
    func deleteSpecificItems(_ items: [ScheduleItem]) {
        guard let competition = competition else { return }
        
        for item in items {
            if let idx = competition.schedule.firstIndex(where: { $0.persistentModelID == item.persistentModelID }) {
                competition.schedule.remove(at: idx)
            }
        }
        
        reindexFromDisplayedOrder()
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
