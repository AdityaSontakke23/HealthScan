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
        let colors = colorScheme == .dark
            ? [darkBlue, primaryBlue.opacity(0.75)]
            : [primaryBlue, primaryBlue.opacity(0.65), accentOrange.opacity(0.6)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 14) {
                VStack(spacing: 6) {
                    Text(cameraManager.contactState == .noFinger ? "Finger Not Detected" : "Please keep still")
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
                
                // Contact state alert banner — stays visible until finger is properly placed and calibrated
                if cameraManager.contactState != .measuring {
                    contactAlertBanner
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
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("PPG Signal")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.85))
                    PPGWaveformView(samples: cameraManager.filteredSamples).frame(height: 140)
                }
                .padding(.horizontal, 20)
                
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
    
    private var contactAlertBanner: some View {
        HStack(spacing: 12) {
            if cameraManager.contactState == .calibrating {
                ProgressView().tint(.white)
            } else {
                Image(systemName: "hand.point.up.left.fill").font(.system(size: 20, weight: .semibold)).foregroundStyle(.yellow)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(cameraManager.contactState == .calibrating ? "Calibrating Sensor..." : "Place Finger Over Camera & Flash")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(cameraManager.contactState == .calibrating ? "Hold steady for a moment while light locks." : "Scan is paused until your fingertip covers both the lens and flash.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.black.opacity(0.55))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25), lineWidth: 1))
        .padding(.horizontal, 24)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    private var countdownSection: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center) {
                Button(action: cancelRecording) {
                    Image(systemName: "xmark").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 42, height: 42).background(Color.red.opacity(0.28)).clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
                }
                .accessibilityLabel("Cancel and discard")
                Spacer()
                Text("\(cameraManager.timeRemaining)")
                    .font(.system(size: 56, weight: .bold, design: .rounded)).foregroundStyle(.white).monospacedDigit().frame(minWidth: 120)
                Spacer()
                Button(action: finishEarly) {
                    Image(systemName: "stop.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 42, height: 42).background(Color.green.opacity(0.35)).clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
                }
                .accessibilityLabel("Stop now and save")
            }
            .padding(.horizontal, 24)
            
            Text(cameraManager.contactState == .measuring ? "seconds remaining" : "countdown paused — place finger")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(cameraManager.contactState == .measuring ? Color.white.opacity(0.85) : .yellow)
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
