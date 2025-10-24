//
//  IntervalTimerSettingsView.swift
//  Performance Archery
//
//  Created by Luke Myers on 23/08/2025.
//

import SwiftUI

struct IntervalTimerSettingsView: View {
    @State private var workSeconds: Int = 20
    @State private var restSeconds: Int = 40
    @State private var reps: Int = 1
    @State private var startDelaySeconds: Int = 10
    @State private var showTimer = false

    private func mmss(_ s: Int) -> String {
        String(format: "%01d:%02d", s/60, s%60)
    }

    var body: some View {
        VStack(spacing: 50) {
            VStack {
                Text("Work — \(mmss(workSeconds))").font(.title)
                HStack {
                    Button(action: { workSeconds = max(5, workSeconds - 5) }) {
                        Image(systemName: "minus.circle").font(.title)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(workSeconds) },
                            set: { workSeconds = min(60, max(5, Int((($0 / 5).rounded()) * 5))) }
                        ),
                        in: 5...60,
                        step: 1
                    )
                    Button(action: { workSeconds = min(60, workSeconds + 5) }) {
                        Image(systemName: "plus.circle").font(.title)
                    }
                }
            }

            VStack {
                Text("Rest — \(mmss(restSeconds))").font(.title)
                HStack {
                    Button(action: { restSeconds = max(5, restSeconds - 5) }) {
                        Image(systemName: "minus.circle").font(.title)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(restSeconds) },
                            set: { restSeconds = min(60, max(5, Int((($0 / 5).rounded()) * 5))) }
                        ),
                        in: 5...60,
                        step: 1
                    )
                    Button(action: { restSeconds = min(60, restSeconds + 5) }) {
                        Image(systemName: "plus.circle").font(.title)
                    }
                }
            }
            
            VStack {
                Text("Start Delay — \(mmss(startDelaySeconds))").font(.title)
                HStack {
                    Button(action: { startDelaySeconds = max(0, startDelaySeconds - 5) }) {
                        Image(systemName: "minus.circle").font(.title)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(startDelaySeconds) },
                            set: { startDelaySeconds = min(30, max(0, Int((( $0 / 5 ).rounded()) * 5))) }
                        ),
                        in: 0...30,
                        step: 1
                    )
                    Button(action: { startDelaySeconds = min(30, startDelaySeconds + 5) }) {
                        Image(systemName: "plus.circle").font(.title)
                    }
                }
            }
            
            VStack {
                Text("Repetitions").font(.title)

                HStack {
                    Button(action: { reps = max(1, reps - 1) }) {
                        Image(systemName: "minus.circle").font(.title)
                    }

                    TextField("", value: $reps, formatter: NumberFormatter())
                        .frame(width: 50)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .font(.title)

                    Button(action: { reps = min(99, reps + 1) }) {
                        Image(systemName: "plus.circle").font(.title)
                    }
                }
            }
            
            Button("START") {
                showTimer = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .font(.title)
            .fullScreenCover(isPresented: $showTimer) {
                TimerView(workSeconds: workSeconds, restSeconds: restSeconds, totalReps: reps, startDelaySeconds: startDelaySeconds)
            }
        }
        .padding()
    }
}

#Preview {
    IntervalTimerSettingsView()
}
