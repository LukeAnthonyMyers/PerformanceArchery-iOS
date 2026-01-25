//
//  ContentView.swift
//  Performance Archery
//
//  Created by Luke Myers on 05/01/2025.
//

import SwiftUI
import SwiftData
import AVFoundation

struct ContentView: View {
    @State private var cameraAuthStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    
    var body: some View {
        ZStack {
            TabView {
                CalendarView()
                    .tabItem() {
                        Label("Calendar", systemImage: "calendar")
                    }
                ActivitiesView()
                    .tabItem() {
                        Label("Activities", systemImage: "figure.archery")
                    }
                ToolsView()
                    .tabItem() {
                        Label("Tools", systemImage: "wrench.and.screwdriver.fill")
                    }
                TrainingLogView()
                    .tabItem() {
                        Label("Training Log", systemImage: "list.bullet.clipboard")
                    }
                EquipmentView()
                    .tabItem() {
                        Label("Equipment", systemImage: "pencil.and.ruler")
                    }
            }
        }
        .task {
            await requestCameraPermissionOnLaunch()
        }
    }
    
    @MainActor
    private func updateAuthStatus() {
        cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    private func requestCameraPermissionOnLaunch() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                self.cameraAuthStatus = granted ? .authorized : AVCaptureDevice.authorizationStatus(for: .video)
            }
        } else {
            await MainActor.run { self.cameraAuthStatus = status }
        }
    }
}

#Preview {
    ContentView()
}
