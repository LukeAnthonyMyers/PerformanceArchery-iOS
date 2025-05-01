//
//  Performance_ArcheryApp.swift
//  Performance Archery
//
//  Created by Luke Myers on 05/01/2025.
//

import SwiftUI
import SwiftData

@main
struct Performance_ArcheryApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TrainingSession.self,
            CoachingSession.self,
            Competition.self,
        ])
        // Use in-memory store for previews, persistent store for app
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isPreview)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
