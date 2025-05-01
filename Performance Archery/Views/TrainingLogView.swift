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
    @Query private var trainingSessions: [TrainingSession]
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(trainingSessions) { session in
                    NavigationLink {
                        Text("Training session on \(session.dateTime, format: Date.FormatStyle(date: .numeric, time: .shortened))")
                        
                        Spacer()
                        
                        HStack(spacing: 50) {
                            VStack {
                                Text("Shots\n\(session.arrowCount)").font(.system(size: 30))
                                    .multilineTextAlignment(.center)
                                Button(action: {
                                    session.arrowCount += 1
                                }) {
                                    Label("Increment", systemImage: "plus")
                                }
                                Button(action: {
                                    if session.arrowCount > 0 {
                                        session.arrowCount -= 1
                                    }
                                }) {
                                    Label("Decrement", systemImage: "minus")
                                }
                            }
                            
                            VStack {
                                Text("Come Downs\n\(session.comeDowns)").font(.system(size: 30))
                                    .multilineTextAlignment(.center)
                                Button(action: {
                                    session.comeDowns += 1
                                }) {
                                    Label("Increment", systemImage: "plus")
                                }
                                Button(action: {
                                    if session.comeDowns > 0 {
                                        session.comeDowns -= 1
                                    }
                                }) {
                                    Label("Decrement", systemImage: "minus")
                                }
                            }
                        }
                        
                        Spacer()
                    } label: {
                        Text(session.dateTime, format: Date.FormatStyle(date: .long, time: .shortened))
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
        } detail: {
            Text("Select an item")
        }
    }
    
    private func addItem() {
//        withAnimation {
//            let newItem = TrainingSession(dateTime: Date())
//            modelContext.insert(newItem)
//        }
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
        .modelContainer(for: TrainingSession.self, inMemory: true)
}
