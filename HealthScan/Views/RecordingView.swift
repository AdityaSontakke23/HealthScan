//
//  RecordingView.swift
//  ClimbPulse
//
//  Live recording screen showing PPG waveform, BPM, and countdown timer.
//

import SwiftUI
@preconcurrency import AVFoundation

struct RecordingView: View {
    var cameraManager: CameraManager
    let onComplete: (Measurement?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showCalibrating = false
    
    // JYU-inspired palette: deep blue + vivid orange
    private let primaryBlue = Color(red: 0.0, green: 0.34, blue: 0.65)      // #0056A5
    private let darkBlue = Color(red: 0.02, green: 0.16, blue: 0.32)       // #042948
    private let accentOrange = Color(red: 1.0, green: 0.51, blue: 0.0)     // #FF8200
    private let accentYellow = Color(red: 1.0, green: 0.72, blue: 0.11)    // #FFB81C
    
    private var recordingProgress: Double {
        guard cameraManager.recordingLength > 0 else { return 0 }
        let elapsed = Double(cameraManager.recordingLength - cameraManager.timeRemaining)
        return max(0, min(1, elapsed / Double(cameraManager.recordingLength)))
    }
    
    private var backgroundGradient: LinearGradient {
        let colors: [Color]
        if colorScheme == .dark {
            colors = [darkBlue, primaryBlue.opacity(0.75)]
        } else {
            colors = [primaryBlue, primaryBlue.opacity(0.65), accentOrange.opacity(0.6)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("Please keep still")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Gently cover the rear camera and flash with your fingertip.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 8)
                
                BPMPreviewRing(
                    session: cameraManager.captureSession,
                    bpm: cameraManager.currentBPM,
                    progress: recordingProgress,
                    quality: cameraManager.signalQuality,
                    accent: accentOrange,
                    glow: accentYellow
                )
                
                // Contact state overlay — shown while sensor calibrates
                if cameraManager.contactState == .calibrating {
                    VStack(spacing: 10) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.3)
                        Text("Hold still — calibrating sensor...")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(16)
                    .background(Color.black.opacity(0.6))
                    .clipShape(.rect(cornerRadius: 16))
                    .padding(.horizontal, 40)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                if cameraManager.countdownStarted {
                    countdownSection
                } else {
                    Button(action: cancelRecording) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                            Text("Cancel")
                        }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.28))
                        .clipShape(Capsule())
                    }
                }
                
                // PPG Waveform
                VStack(alignment: .leading, spacing: 6) {
                    Text("PPG Signal")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.85))
                    
                    PPGWaveformView(samples: cameraManager.filteredSamples)
                        .frame(height: 150)
                }
                .padding(.horizontal, 20)
                
                // Instructions
                VStack(spacing: 10) {
                    FingerPlacementIndicator(
                        sampleCount: cameraManager.samples.count,
                        signalQuality: cameraManager.signalQuality,
                        contactState: cameraManager.contactState
                    )
                    
                    Text("Keep your finger steady on the rear camera + flash")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 8)
            }
            .padding(.vertical, 12)
            .animation(.easeInOut(duration: 0.3), value: cameraManager.contactState)
        }
        .onAppear { startRecording() }
    }
    
    private var countdownSection: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center) {
                Button(action: cancelRecording) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.red.opacity(0.28))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
                }
                .accessibilityLabel("Cancel and discard")
                
                Spacer()
                
                Text("\(cameraManager.timeRemaining)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .frame(minWidth: 120)
                
                Spacer()
                
                Button(action: finishEarly) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.green.opacity(0.35))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
                }
                .accessibilityLabel("Stop now and save")
            }
            .padding(.horizontal, 24)
            
            Text("seconds remaining")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.85))
        }
    }
    
    private func startRecording() {
        cameraManager.onRecordingComplete = { measurement in onComplete(measurement) }
        cameraManager.startRecording()
    }
    
    private func finishEarly() { cameraManager.stopRecording() }
    
    private func cancelRecording() {
        cameraManager.stopRecording()
        dismiss()
        onComplete(nil)
    }
}

#Preview {
    RecordingView(cameraManager: CameraManager()) { _ in }
}
