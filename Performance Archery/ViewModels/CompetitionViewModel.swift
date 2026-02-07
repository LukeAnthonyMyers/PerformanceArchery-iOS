//
//  CompetitionViewModel.swift
//  Performance Archery
//
//  Created by Luke Myers on 01/02/2026.
//

import SwiftData
import SwiftUI

@Observable
class CompetitionViewModel {
    var competition: Competition

    init(competition: Competition) {
        self.competition = competition
    }

    var displayedSchedule: [ScheduleItem] {
        competition.schedule.sorted { $0.index < $1.index }
    }

    func addScheduleItem() {
        let newItem = ScheduleItem(title: "", index: competition.schedule.count)
        competition.schedule.append(newItem)
    }

    func deleteItems(at offsets: IndexSet) {
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
}
