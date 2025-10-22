//
//  TimerView.swift
//  Performance Archery
//
//  Created by Luke Myers on 20/09/2025.
//

import SwiftUI
import AVFoundation

struct TimerView: View {
    enum Phase {
        case startDelay
        case work
        case rest
        case finished

        var label: String {
            switch self {
            case .startDelay: return "Get Ready"
            case .work: return "Work"
            case .rest: return "Rest"
            case .finished: return "Done"
            }
        }

        var color: Color {
            switch self {
            case .startDelay: return .orange
            case .work: return .green
            case .rest: return .red
            case .finished: return .gray
            }
        }
    }

    let workSeconds: Int
    let restSeconds: Int
    let totalReps: Int
    let startDelaySeconds: Int
    @Environment(\.dismiss) private var dismiss

    @State private var phase: Phase = .work
    @State private var currentRep: Int = 1
    @State private var remaining: Int = 0
    @State private var totalPhaseDuration: Int = 0
    @State private var isRunning: Bool = true
    @State private var phaseStartDate: Date = .now
    @State private var pausedElapsed: Double? = nil
    
    @StateObject private var tonePlayer = AVEngineTonePlayer()
    @State private var lastBeepSecond: Int = -1

    private func startPhase(_ newPhase: Phase) {
        pausedElapsed = nil
        phase = newPhase
        phaseStartDate = .now
        switch newPhase {
        case .startDelay:
            remaining = max(0, startDelaySeconds)
            totalPhaseDuration = max(0, startDelaySeconds)
        case .work:
            remaining = max(1, workSeconds)
            totalPhaseDuration = max(1, workSeconds)
        case .rest:
            remaining = max(1, restSeconds)
            totalPhaseDuration = max(1, restSeconds)
        case .finished:
            remaining = 0
            totalPhaseDuration = 1
            isRunning = false
        }
        lastBeepSecond = -1
    }

    private func advance() {
        if phase == .startDelay {
            startPhase(.work)
            return
        }

        if phase == .work {
            if currentRep < totalReps && restSeconds > 0 {
                startPhase(.rest)
            } else {
                if currentRep < totalReps {
                    currentRep += 1
                    startPhase(.work)
                } else {
                    startPhase(.finished)
                }
            }
        } else if phase == .rest {
            if currentRep < totalReps {
                currentRep += 1
                startPhase(.work)
            } else {
                startPhase(.finished)
            }
        }
    }

    private func resetCurrentPhaseToStart() {
        switch phase {
        case .startDelay:
            startPhase(.startDelay)
        case .work:
            startPhase(.work)
        case .rest:
            startPhase(.rest)
        case .finished:
            break
        }
    }

    private func progress(currentDate: Date = .now) -> Double {
        guard totalPhaseDuration > 0 else { return 0 }
        let elapsed: Double
        if isRunning {
            elapsed = max(0, currentDate.timeIntervalSince(phaseStartDate))
        } else if let paused = pausedElapsed {
            elapsed = max(0, paused)
        } else {
            elapsed = max(0, Double(totalPhaseDuration - remaining))
        }
        return min(1, max(0, elapsed / Double(totalPhaseDuration)))
    }

    private func computedRemaining(currentDate: Date = .now) -> Int {
        let elapsed: Double
        if isRunning {
            elapsed = currentDate.timeIntervalSince(phaseStartDate)
        } else if let paused = pausedElapsed {
            elapsed = paused
        } else {
            elapsed = Double(totalPhaseDuration - remaining)
        }
        let left = Double(totalPhaseDuration) - elapsed
        return max(0, Int(ceil(left)))
    }

    private func mmss(_ s: Int) -> String {
        String(format: "%01d:%02d", s/60, s%60)
    }

    var body: some View {
        ZStack {
            phase.color.opacity(0.1).ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 25, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal)
                .accessibilityLabel("Close")

                Text("Rep \(min(currentRep, totalReps))/\(totalReps)")
                    .font(.title)
                    .foregroundStyle(.secondary)

                TimelineView(.animation) { context in
                    let prog = progress(currentDate: context.date)
                    let rem = computedRemaining(currentDate: context.date)

                    GeometryReader { proxy in
                        let horizontalInset: CGFloat = 28
                        let verticalInset: CGFloat = 28
                        let availableWidth = proxy.size.width - (horizontalInset * 2)
                        let availableHeight = proxy.size.height - (verticalInset * 2)
                        let dialSize = min(availableWidth, availableHeight)

                        ZStack {
                            Circle()
                                .stroke(lineWidth: 25)
                                .foregroundStyle(.quaternary)
                                .frame(width: dialSize, height: dialSize)

                            Circle()
                                .trim(from: 0, to: CGFloat(prog))
                                .stroke(phase.color.gradient, style: StrokeStyle(lineWidth: 25, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: dialSize, height: dialSize)
                                .animation(nil, value: prog)

                            VStack(spacing: 8) {
                                Text(mmss(rem))
                                    .font(.system(size: 64, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                Text(phase.label)
                                    .font(.title)
                                    .foregroundStyle(phase.color)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.horizontal, horizontalInset)
                        .padding(.vertical, verticalInset)
                    }
                }

                GeometryReader { geo in
                    ZStack {
                        Button(action: { isRunning.toggle() }) {
                            Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 100, weight: .regular))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.primary)
                        }
                        .accessibilityLabel(isRunning ? "Pause" : "Resume")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                        Button(action: {
                            resetCurrentPhaseToStart()
                        }) {
                            Image(systemName: "backward.end.circle.fill")
                                .font(.system(size: 64, weight: .regular))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.primary)
                        }
                        .accessibilityLabel("Skip Back")
                        .position(x: geo.size.width / 4, y: geo.size.height / 2)
                    }
                }
                .frame(height: 120)

                Spacer()
            }
        }
        .onAppear {
            currentRep = 1
            tonePlayer.startEngine()

            if startDelaySeconds > 0 {
                startPhase(.startDelay)
            } else {
                startPhase(.work)
            }
        }
        .onChange(of: isRunning) { _, running in
            if running {
                if let paused = pausedElapsed {
                    phaseStartDate = Date().addingTimeInterval(-paused)
                } else {
                    phaseStartDate = .now
                }
                pausedElapsed = nil
            } else {
                pausedElapsed = max(0, Date().timeIntervalSince(phaseStartDate))
            }
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard phase != .finished else { return }
            let rem = computedRemaining()

            if isRunning && rem > 0 && rem <= 3 && rem != lastBeepSecond {
                tonePlayer.playShortBeep()
                lastBeepSecond = rem
            }

            if isRunning && progress() >= 1.0 {
                let willFinish: Bool = {
                    switch phase {
                    case .startDelay:
                        return false
                    case .work:
                        if currentRep < totalReps && restSeconds > 0 {
                            return false
                        } else {
                            return currentRep >= totalReps
                        }
                    case .rest:
                        return currentRep >= totalReps
                    case .finished:
                        return false
                    }
                }()

                if willFinish {
                    tonePlayer.playCompletionBeeps()
                } else {
                    tonePlayer.playFinishBeep()
                }
                lastBeepSecond = -1
                advance()
            }
        }
        .onDisappear {
            tonePlayer.stopEngine()
        }
    }
}

final class AVEngineTonePlayer: ObservableObject {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100.0
    private let format: AVAudioFormat

    init() {
        self.format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 1.0
    }

    func startEngine() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)

            if !engine.isRunning {
                try engine.start()
            }

            if !player.isPlaying {
                player.play()
            }

        } catch {
            print("AVEngineTonePlayer: could not start engine: \(error)")
        }
    }

    func stopEngine() {
        if player.isPlaying {
            player.stop()
        }

        if engine.isRunning {
            engine.stop()
        }

        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
        }
    }

    deinit {
        stopEngine()
    }

    private func playTone(frequency: Double, duration: Double) {
        guard duration > 0 else { return }
        let frameCount = Int(ceil(duration * sampleRate))
        guard frameCount > 0 else { return }

        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = buffer.frameCapacity

        let channelData = buffer.floatChannelData![0]
        let twoPi = 2.0 * Double.pi

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            let sample = sin(twoPi * frequency * t)
            let fadeInOut = envelope(i: i, frameCount: frameCount)
            channelData[i] = Float(sample) * fadeInOut
        }

        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)

        if !player.isPlaying {
            player.play()
        }
    }

    private func envelope(i: Int, frameCount: Int) -> Float {
        let fadeLengthSamples = max(1, Int(min(0.005 * sampleRate, Double(frameCount) * 0.15)))

        if i < fadeLengthSamples {
            return Float(i) / Float(fadeLengthSamples)
        } else if i > frameCount - fadeLengthSamples {
            return Float(frameCount - i) / Float(fadeLengthSamples)
        } else {
            return 1.0
        }
    }

    func playShortBeep() {
        playTone(frequency: 1200, duration: 0.125)
    }

    func playFinishBeep() {
        playTone(frequency: 1500, duration: 0.25)
    }
    
    func playCompletionBeeps() {
        playTone(frequency: 1000, duration: 0.125)
        playTone(frequency: 1600, duration: 0.125)
    }
}

#Preview {
    TimerView(workSeconds: 5, restSeconds: 5, totalReps: 2, startDelaySeconds: 0)
}
