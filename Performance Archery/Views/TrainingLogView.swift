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
    @Query private var trainingSessions: [Item]
    
    var body: some View {
        NavigationSplitView {
            Text("Training Log")
            List {
                ForEach(trainingSessions) { session in
                    NavigationLink {
                        Text("Training session on \(session.timestamp, format: Date.FormatStyle(date: .numeric, time: .shortened))")
                        Text("Arrows shot: \(session.arrowCount)").font(.system(size: 50))
                        Button(action: {
                            session.arrowCount += 1
                        }) {
                            Label("Increment", systemImage: "plus")
                        }
                        Button(action: {
                            if session.arrowCount != 0 {
                                session.arrowCount -= 1
                            }
                        }) {
                            Label("Decrement", systemImage: "minus")
                        }
                    } label: {
                        Text(session.timestamp, format: Date.FormatStyle(date: .long, time: .shortened))
                        Text("Arrows: " + String(session.arrowCount))
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
        } detail: {
            Text("Select an item")
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
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
        .modelContainer(for: Item.self, inMemory: true)
}
