//
//  ContentView.swift
//  Performance Archery
//
//  Created by Luke Myers on 05/01/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State var count: Int = 0

    var body: some View {
        Text("Training Log")
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Training session on \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        Text("Arrows shot: \(count)")
                        Button(action: {
                            self.count += 1
                        }) {
                            Text("Increment")
                        }
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .long, time: .shortened))
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
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
