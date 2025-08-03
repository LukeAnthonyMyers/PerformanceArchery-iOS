//
//  TrainingLogView.swift
//  Performance Archery
//
//  Created by Luke Myers on 05/01/2025.
//

import SwiftUI
import SwiftData

struct TrainingLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var trainingSessions: [ShootingSession]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(trainingSessions) { session in
                    NavigationLink(value: session) {
                        Text(session.dateTime, format: Date.FormatStyle(date: .long, time: .omitted))
                        Text("Shots: " + String(session.arrowCount))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Training Log")
            .navigationDestination(for: ShootingSession.self) { session in
                ShootingSessionView(session: session)
            }
        }
    }
    
    private func addItem() {
        let session = ShootingSession(
            dateTime: Date(),
            goals: "",
            reflection: "",
            locationName: "",
            location: nil
        )
        modelContext.insert(session)
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(trainingSessions[index])
            }
        }
    }
}

#Preview {
    TrainingLogView()
        .modelContainer(for: ShootingSession.self, inMemory: true)
}
