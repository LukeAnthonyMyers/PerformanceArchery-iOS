//
//  ToolsView.swift
//  Performance Archery
//
//  Created by Luke Myers on 23/08/2025.
//

import SwiftUI

struct ToolsView: View {
    enum ToolType {
            case intervalTimer
        }

        struct ToolItem: Identifiable {
            let id = UUID()
            let title: String
            let systemImage: String
            let type: ToolType
        }

        let tools: [ToolItem] = [
            .init(title: "Interval Timer", systemImage: "timer", type: .intervalTimer)
        ]
    var body: some View {
        NavigationStack {
            List(tools) { tool in
                NavigationLink(value: tool.type) {
                    Label(tool.title, systemImage: tool.systemImage)
                }
            }
            .navigationTitle("Tools")
            .navigationDestination(for: ToolType.self) { type in
                destination(for: type)
            }
        }
    }
    
    @ViewBuilder
    private func destination(for type: ToolType) -> some View {
        switch type {
            case .intervalTimer: IntervalTimerSettingsView()
        }
    }
}

#Preview {
    ToolsView()
}
