//
//  VideoDelayView.swift
//  Performance Archery
//
//  Created by Luke Myers on 24/10/2025.
//

import SwiftUI
import AVFoundation
import UIKit

struct VideoDelayView: View {
    @StateObject private var camera = DelayedCameraController()
    @State private var delay: Double = 0
    @State private var isShowingControls: Bool = true
    @State private var authStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var isLooping: Bool = false
    @State private var isLoopPaused: Bool = false
    @State private var scrubIndex: Double = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            CameraPreviewView(session: camera.session, pixelBuffer: $camera.displayPixelBuffer, fallbackPixelBuffer: $camera.fallbackPixelBuffer)
                .ignoresSafeArea()
                .background(Color.black)
                .onTapGesture { withAnimation { isShowingControls.toggle() } }
                .opacity(authStatus == .authorized ? 1 : 0.2)

            if authStatus != .authorized {
                permissionOverlay
            } else if isShowingControls {
                controls
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task { @MainActor in
            await requestCameraPermissionIfNeeded()
        }
        .onAppear {
            camera.setDelay(seconds: delay)
            camera.setLoopLength(seconds: delay)
            if authStatus == .authorized { camera.startIfAuthorized() }
        }
        .onDisappear { camera.stop(); camera.stopLooping() }
        .onChange(of: delay) { _, newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak camera] in
                camera?.setDelay(seconds: newValue)
                camera?.setLoopLength(seconds: newValue)
            }
        }
        .onChange(of: authStatus) { _, newStatus in
            DispatchQueue.main.async {
                if newStatus == .authorized {
                    camera.startIfAuthorized()
                } else {
                    camera.stop()
                }
            }
        }
        .toolbar(isShowingControls ? .visible : .hidden, for: .navigationBar)
        .toolbar(isShowingControls ? .visible : .hidden, for: .tabBar)
        .navigationBarBackButtonHidden(!isShowingControls)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { camera.flipCamera() }) {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 22, weight: .semibold))
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }
                
                if camera.hasPrimedLoop {
                    Spacer()
                    Button(action: {
                        isLooping.toggle()
                        if isLooping {
                            isLoopPaused = false
                            scrubIndex = 0
                            camera.startLooping()
                        } else {
                            isLoopPaused = false
                            camera.stopLooping()
                        }
                    }) {
                        Image(systemName: isLooping ? "repeat.circle.fill" : "repeat.circle")
                            .font(.system(size: 24, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                } else {
                    Spacer()
                }

                Text(String(format: "%ds", Int(delay)))
                    .font(.system(.title3, weight: .semibold))
                    .padding(8)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(.horizontal)

            HStack(spacing: 8) {
                Image(systemName: "clock")
                Slider(
                    value: Binding(
                        get: { delay },
                        set: { delay = max(0, min(15, $0.rounded())) }
                    ),
                    in: 0...15,
                    step: 1
                )
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .disabled(isLooping)
            
            if isLooping {
                HStack(spacing: 12) {
                    Button(action: {
                        if isLoopPaused {
                            isLoopPaused = false
                            camera.resumeLooping()
                        } else {
                            let current = camera.currentLoopIndex()
                            scrubIndex = Double(current)
                            camera.scrubLoop(to: current)
                            camera.pauseLooping()
                            isLoopPaused = true
                        }
                    }) {
                        Image(systemName: isLoopPaused ? "play.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .padding(6)
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    Slider(
                        value: Binding(
                            get: {
                                isLoopPaused ? scrubIndex : Double(camera.currentLoopIndex())
                            },
                            set: { newVal in
                                scrubIndex = newVal
                                if isLoopPaused {
                                    camera.scrubLoop(to: Int(newVal))
                                }
                            }
                        ),
                        in: 0...Double(max(0, camera.loopFrameCount() - 1)),
                        step: 1,
                        onEditingChanged: { editing in
                            if editing {
                                camera.pauseLooping()
                                isLoopPaused = true
                            } else {
                                camera.scrubLoop(to: Int(scrubIndex))
                            }
                        }
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            if camera.isPriming {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.15))
                        Capsule()
                            .fill(.white)
                            .frame(width: max(4, geo.size.width * camera.primingProgress))
                    }
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.2), value: camera.primingProgress)
                }
                .frame(height: 4)
                .padding(.horizontal)
                .padding(.bottom, 6)
            }
        }
        .padding(.vertical, 12)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.6), Color.black.opacity(0.0)]), startPoint: .bottom, endPoint: .top)
                .ignoresSafeArea(edges: .bottom)
        )
        .foregroundStyle(.white)
    }

    private var permissionOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .padding(.bottom, 4)
            Text("Camera Access Needed")
                .font(.title2).bold()
            Text("To use Video Delay, please allow camera access in Settings.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                if authStatus == .notDetermined {
                    Button("Allow Camera Access") {
                        Task { await requestCameraPermissionIfNeeded(forceRequest: true) }
                    }
                    .buttonStyle(.borderedProminent)
                }
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(maxWidth: 360)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding()
    }

    @MainActor
    private func requestCameraPermissionIfNeeded(forceRequest: Bool = false) async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        if status == .notDetermined || forceRequest {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authStatus = granted ? .authorized : AVCaptureDevice.authorizationStatus(for: .video)
        } else {
            authStatus = status
        }
    }
}

final class DelayedCameraController: NSObject, ObservableObject {
    let session = AVCaptureSession()

    @Published var displayPixelBuffer: CVPixelBuffer?
    @Published var fallbackPixelBuffer: CVPixelBuffer?
    @Published var isPriming: Bool = false
    @Published var primingProgress: Double = 0
    @Published var hasPrimedDelay: Bool = false
    @Published var hasPrimedLoop: Bool = false

    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    private var ring: [CVPixelBuffer?] = []
    private var ringCapacity: Int = 1
    private var writeIndex: Int = 0
    private var pixelBufferPool: CVPixelBufferPool?

    private var targetDelaySeconds: Double = 0
    private var averageFrameDuration: Double = 1.0 / 30.0
    private var lastTimestamp: CMTime?

    private var needsFallbackSnapshot: Bool = false

    @Published var isLooping: Bool = false
    private var loopFrames: [CVPixelBuffer] = []
    private var loopIndex: Int = 0
    private var loopTimer: DispatchSourceTimer?
    private var loopTimerSuspended: Bool = false
    private var loopFrameDuration: Double { max(1.0 / 60.0, min(1.0, averageFrameDuration)) }
    private var loopLengthSeconds: Double = 0

    func setDelay(seconds: Double) {
        targetDelaySeconds = max(0, min(15, seconds))
        updateRingCapacityForDelay()
    }

    func startIfAuthorized() {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else { return }
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            self.stopLoopTimer()
            DispatchQueue.main.async { self.isLooping = false }

            if !self.session.isRunning {
                self.configureSession(position: .back)
                self.session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.stopLoopTimer()
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.stopLoopTimer()
            self.isLooping = false

            guard let currentInput = self.session.inputs.first as? AVCaptureDeviceInput else { return }

            let newPosition: AVCaptureDevice.Position = (currentInput.device.position == .back) ? .front : .back
            self.session.beginConfiguration()
            self.session.removeInput(currentInput)
            
            if let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
               let newInput = try? AVCaptureDeviceInput(device: newDevice),
               self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
            } else {
                if self.session.canAddInput(currentInput) { self.session.addInput(currentInput) }
            }
            self.session.commitConfiguration()
            
            if let connection = self.videoOutput.connection(with: .video),
               let newInput = self.session.inputs.first as? AVCaptureDeviceInput {
                connection.automaticallyAdjustsVideoMirroring = false
                
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = (newInput.device.position == .front)
                }
                
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
            }

            self.needsFallbackSnapshot = true
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.hasPrimedDelay = false
                self.hasPrimedLoop = false
                self.isPriming = self.ringCapacity > 1 && self.targetDelaySeconds > 0
                self.primingProgress = 0
            }
        }
    }

    func setLoopLength(seconds: Double) {
        loopLengthSeconds = max(0, min(15, seconds))
    }

    func startLooping() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.captureLoopFrames()
            guard !self.loopFrames.isEmpty else { return }
            DispatchQueue.main.async { self.isLooping = true }
            self.startLoopTimer()
        }
    }

    func stopLooping() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async { self.isLooping = false }
            self.stopLoopTimer()
            self.loopFrames.removeAll()
            self.loopIndex = 0
        }
    }
    
    func pauseLooping() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard let t = self.loopTimer, !self.loopTimerSuspended else { return }
            t.suspend()
            self.loopTimerSuspended = true
        }
    }

    func resumeLooping() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.isLooping else { return }

            if self.loopTimer == nil {
                self.startLoopTimer()
            } else if self.loopTimerSuspended {
                self.loopTimer?.resume()
                self.loopTimerSuspended = false
            }
        }
    }

    func loopFrameCount() -> Int { loopFrames.count }
    func currentLoopIndex() -> Int { loopIndex }

    func scrubLoop(to index: Int) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.loopFrames.isEmpty else { return }
            let clamped = max(0, min(index, self.loopFrames.count - 1))
            self.loopIndex = clamped
            let pb = self.loopFrames[clamped]
            DispatchQueue.main.async { [weak self] in
                self?.displayPixelBuffer = pb
            }
        }
    }

    private func captureLoopFrames() {
        let fps = max(5.0, min(120.0, 1.0 / averageFrameDuration))
        let framesForX = max(1, Int(round(loopLengthSeconds * fps)))
        guard ring.count >= framesForX * 2 + 1 else { return }
        let delayedReadIdx = (writeIndex - framesForX + ring.count) % ring.count
        let startIdx = (delayedReadIdx - framesForX + ring.count) % ring.count
        var frames: [CVPixelBuffer] = []
        var idx = startIdx
        var taken = 0

        while taken < framesForX {
            if let pb = ring[idx] {
                frames.append(pb)
            }

            idx = (idx + 1) % ring.count
            taken += 1
        }

        self.loopFrames = frames
        self.loopIndex = 0
    }

    private func startLoopTimer() {
        stopLoopTimer()
        guard !loopFrames.isEmpty else { return }
        let timer = DispatchSource.makeTimerSource(queue: sessionQueue)
        let interval = max(loopFrameDuration, 1e-3)

        timer.schedule(deadline: .now(), repeating: interval)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            guard self.isLooping, !self.loopFrames.isEmpty else { return }
            let pb = self.loopFrames[self.loopIndex]
            self.loopIndex = (self.loopIndex + 1) % self.loopFrames.count
            DispatchQueue.main.async { [weak self] in
                self?.displayPixelBuffer = pb
            }
        }

        loopTimer = timer
        loopTimerSuspended = false
        timer.resume()
    }

    private func stopLoopTimer() {
        if let t = loopTimer {
            if loopTimerSuspended {
                t.resume()
                loopTimerSuspended = false
            }
            t.cancel()
        }
        loopTimer = nil
    }

    private func configureSession(position: AVCaptureDevice.Position) {
        self.session.beginConfiguration()
        self.session.sessionPreset = .hd1920x1080

        self.session.inputs.forEach { self.session.removeInput($0) }
        
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
           let input = try? AVCaptureDeviceInput(device: device),
           self.session.canAddInput(input) {
            self.session.addInput(input)
        }

        self.session.outputs.forEach { self.session.removeOutput($0) }
        self.videoOutput.alwaysDiscardsLateVideoFrames = false
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
        
        if self.session.canAddOutput(self.videoOutput) {
            self.session.addOutput(self.videoOutput)
        }

        if let connection = self.videoOutput.connection(with: .video) {
            connection.automaticallyAdjustsVideoMirroring = false

            switch position {
                case .front:
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = true
                    }
                    
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                default:
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = false
                    }
                    
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
            }
        }

        self.session.commitConfiguration()
    }

    private func updateRingCapacityForDelay() {
        let fps = max(5.0, min(120.0, 1.0 / averageFrameDuration))
        let framesForX = Int(round(targetDelaySeconds * fps))
        let framesNeeded = max(1, framesForX * 2 + 1)
        let newCapacity = framesNeeded
        
        if newCapacity != ringCapacity || ring.isEmpty {
            ringCapacity = newCapacity
            ring = Array(repeating: nil, count: ringCapacity)
            writeIndex = 0
            DispatchQueue.main.async { [weak self] in
                self?.hasPrimedDelay = false
                self?.hasPrimedLoop = false
                self?.isPriming = (self?.ringCapacity ?? 1) > 1 && (self?.targetDelaySeconds ?? 0) > 0
                self?.primingProgress = 0
            }
        }
    }
}

extension DelayedCameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        if isLooping {
            return
        }

        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        
        if pts.isFinite {
            if let last = lastTimestamp?.seconds {
                let dt = max(1e-3, pts - last)
                averageFrameDuration = 0.9 * averageFrameDuration + 0.1 * dt
            }
            
            lastTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        }

        updateRingCapacityForDelay()

        if ring.isEmpty {
            ring = Array(repeating: nil, count: ringCapacity)
            writeIndex = 0
            hasPrimedDelay = false
            hasPrimedLoop = false
        }

        guard let srcPB = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        if needsFallbackSnapshot {
            needsFallbackSnapshot = false
            let pb = srcPB
            DispatchQueue.main.async { [weak self] in
                self?.fallbackPixelBuffer = pb
            }
        }

        if targetDelaySeconds <= 0.0001 {
            DispatchQueue.main.async { [weak self] in
                self?.isPriming = false
                self?.primingProgress = 1
                self?.displayPixelBuffer = srcPB
            }
            return
        }

        let srcWidth = CVPixelBufferGetWidth(srcPB)
        let srcHeight = CVPixelBufferGetHeight(srcPB)
        let needNewPool: Bool
        
        if let pool = pixelBufferPool, let testAttrs = CVPixelBufferPoolGetPixelBufferAttributes(pool) as? [String: Any] {
            let w = (testAttrs[kCVPixelBufferWidthKey as String] as? Int) ?? 0
            let h = (testAttrs[kCVPixelBufferHeightKey as String] as? Int) ?? 0
            let pixelFormat = (testAttrs[kCVPixelBufferPixelFormatTypeKey as String] as? Int) ?? 0
            needNewPool = (w != srcWidth || h != srcHeight || pixelFormat != kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        } else {
            needNewPool = true
        }
        
        if needNewPool {
            let attrs: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                kCVPixelBufferWidthKey as String: srcWidth,
                kCVPixelBufferHeightKey as String: srcHeight,
                kCVPixelBufferIOSurfacePropertiesKey as String: [:]
            ]
            var pool: CVPixelBufferPool?
            CVPixelBufferPoolCreate(nil, nil, attrs as CFDictionary, &pool)
            pixelBufferPool = pool
            ring = Array(repeating: nil, count: ringCapacity)
            writeIndex = 0
            DispatchQueue.main.async { [weak self] in
                self?.hasPrimedDelay = false
                self?.hasPrimedLoop = false
            }
        }

        var dstPB: CVPixelBuffer?
        if let existing = ring[writeIndex] {
            dstPB = existing
        } else if let pool = pixelBufferPool {
            var newPB: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &newPB)
            dstPB = newPB
        }

        guard let targetPB = dstPB else { return }

        CVPixelBufferLockBaseAddress(srcPB, .readOnly)
        CVPixelBufferLockBaseAddress(targetPB, [])
        
        let planeCount = CVPixelBufferGetPlaneCount(srcPB)
        if planeCount == 2 {
            if let srcBase0 = CVPixelBufferGetBaseAddressOfPlane(srcPB, 0),
               let dstBase0 = CVPixelBufferGetBaseAddressOfPlane(targetPB, 0) {
                let height0 = CVPixelBufferGetHeightOfPlane(srcPB, 0)
                let bytesPerRow0_src = CVPixelBufferGetBytesPerRowOfPlane(srcPB, 0)
                let bytesPerRow0_dst = CVPixelBufferGetBytesPerRowOfPlane(targetPB, 0)
                
                for y in 0..<height0 {
                    let srcPtr = srcBase0.advanced(by: y * bytesPerRow0_src)
                    let dstPtr = dstBase0.advanced(by: y * bytesPerRow0_dst)
                    memcpy(dstPtr, srcPtr, min(bytesPerRow0_src, bytesPerRow0_dst))
                }
            }

            if let srcBase1 = CVPixelBufferGetBaseAddressOfPlane(srcPB, 1),
               let dstBase1 = CVPixelBufferGetBaseAddressOfPlane(targetPB, 1) {
                let height1 = CVPixelBufferGetHeightOfPlane(srcPB, 1)
                let bytesPerRow1_src = CVPixelBufferGetBytesPerRowOfPlane(srcPB, 1)
                let bytesPerRow1_dst = CVPixelBufferGetBytesPerRowOfPlane(targetPB, 1)
                for y in 0..<height1 {
                    let srcPtr = srcBase1.advanced(by: y * bytesPerRow1_src)
                    let dstPtr = dstBase1.advanced(by: y * bytesPerRow1_dst)
                    memcpy(dstPtr, srcPtr, min(bytesPerRow1_src, bytesPerRow1_dst))
                }
            }
        } else {
            let srcBytesPerRow = CVPixelBufferGetBytesPerRow(srcPB)
            let dstBytesPerRow = CVPixelBufferGetBytesPerRow(targetPB)
            let srcHeight = CVPixelBufferGetHeight(srcPB)

            if let srcBase = CVPixelBufferGetBaseAddress(srcPB), let dstBase = CVPixelBufferGetBaseAddress(targetPB) {
                let rowBytes = min(srcBytesPerRow, dstBytesPerRow)

                for y in 0..<srcHeight {
                    let srcPtr = srcBase.advanced(by: y * srcBytesPerRow)
                    let dstPtr = dstBase.advanced(by: y * dstBytesPerRow)
                    memcpy(dstPtr, srcPtr, rowBytes)
                }
            }
        }

        CVPixelBufferUnlockBaseAddress(targetPB, [])
        CVPixelBufferUnlockBaseAddress(srcPB, .readOnly)

        ring[writeIndex] = targetPB
        writeIndex = (writeIndex + 1) % max(ring.count, 1)

        let filled = ring.reduce(0) { $0 + ($1 == nil ? 0 : 1) }
        let fpsNow = max(5.0, min(120.0, 1.0 / averageFrameDuration))
        let framesForXNow = max(1, Int(round(targetDelaySeconds * fpsNow)))

        if !hasPrimedDelay {
            let progress = ringCapacity > 0 ? Double(min(filled, framesForXNow)) / Double(framesForXNow) : 1
            DispatchQueue.main.async { [weak self] in
                self?.isPriming = progress < 1 && (self?.targetDelaySeconds ?? 0) > 0
                self?.primingProgress = min(max(progress, 0), 1)
            }

            if filled < framesForXNow { return }
            DispatchQueue.main.async { [weak self] in
                self?.hasPrimedDelay = true
                self?.isPriming = false
                self?.primingProgress = 1
            }
        }

        if !hasPrimedLoop {
            if filled >= min(ringCapacity, framesForXNow * 2 + 1) {
                DispatchQueue.main.async { [weak self] in
                    self?.hasPrimedLoop = true
                }
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.isPriming = false
            self?.primingProgress = 1
            self?.fallbackPixelBuffer = nil
        }

        let fps = max(5.0, min(120.0, 1.0 / averageFrameDuration))
        let framesForX = max(1, Int(round(targetDelaySeconds * fps)))
        let readIdx = (writeIndex - framesForX + ring.count) % ring.count
        
        if let pb = ring[readIdx] {
            DispatchQueue.main.async { [weak self] in
                self?.displayPixelBuffer = pb
            }
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    @Binding var pixelBuffer: CVPixelBuffer?
    @Binding var fallbackPixelBuffer: CVPixelBuffer?

    func makeUIView(context: Context) -> PreviewUIView {
        let v = PreviewUIView()
        v.videoPreviewLayer.session = session
        v.videoPreviewLayer.videoGravity = .resizeAspectFill
        v.isOpaque = true
        v.layer.contentsScale = UIScreen.main.scale
        return v
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        if let connection = uiView.videoPreviewLayer.connection {
            let input = session.inputs.first as? AVCaptureDeviceInput
            let position = input?.device.position ?? .unspecified
            connection.automaticallyAdjustsVideoMirroring = false

            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = (position == .front)
            }
            
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }
        
        uiView.display(primary: pixelBuffer, fallback: fallbackPixelBuffer)
    }
}

final class PreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    private var ciContext = CIContext()
    private let overlayLayer = CALayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = true
        videoPreviewLayer.masksToBounds = true

        overlayLayer.contentsGravity = .resizeAspectFill
        overlayLayer.frame = bounds
        overlayLayer.backgroundColor = UIColor.clear.cgColor
        layer.addSublayer(overlayLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        overlayLayer.frame = bounds
    }

    func display(primary: CVPixelBuffer?, fallback: CVPixelBuffer?) {
        let chosen = primary ?? fallback
        
        guard let pb = chosen else {
            DispatchQueue.main.async { [weak self] in self?.overlayLayer.contents = nil }
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: pb)
        let rect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pb), height: CVPixelBufferGetHeight(pb))
        
        if let cg = ciContext.createCGImage(ciImage, from: rect) {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.overlayLayer.contents = cg
                self.overlayLayer.frame = self.bounds
            }
        }
    }
}

#Preview {
    VideoDelayView()
}
