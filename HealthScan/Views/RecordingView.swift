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
    
    // Theme colors
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
            
            VStack(spacing: 26) {
                Spacer().frame(height: 36) // push content below dynamic island/status bar
                
                VStack(spacing: 8) {
                    Text("Please keep still")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Gently cover the rear camera and flash with your fingertip.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                
                // Live camera preview shown inside the BPM ring
                BPMPreviewRing(
                    session: cameraManager.captureSession,
                    bpm: cameraManager.currentBPM,
                    progress: recordingProgress,
                    quality: cameraManager.signalQuality,
                    accent: accentOrange,
                    glow: accentYellow
                )
                
                // Countdown timer
                VStack(spacing: 10) {
                    HStack(alignment: .center) {
                        // Cancel (left)
                        Button(action: cancelRecording) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(Color.red.opacity(0.28))
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.35), lineWidth: 1)
                                )
                        }
                        .accessibilityLabel("Cancel and discard")
                        
                        Spacer()
                        
                        // Time center
                        Text("\(cameraManager.timeRemaining)")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .frame(minWidth: 120)
                        
                        Spacer()
                        
                        // Stop/save early (right)
                        Button(action: finishEarly) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(Color.green.opacity(0.35))
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.35), lineWidth: 1)
                                )
                        }
                        .accessibilityLabel("Stop now and save")
                    }
                    .padding(.horizontal, 20)
                    
                    Text("seconds remaining")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
                
                // PPG Waveform
                VStack(alignment: .leading, spacing: 8) {
                    Text("PPG Signal")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.8))
                    
                    PPGWaveformView(samples: cameraManager.filteredSamples)
                        .frame(height: 180)
                }
                .padding(.horizontal, 20)
                
                // Instructions
                VStack(spacing: 12) {
                    FingerPlacementIndicator(
                        sampleCount: cameraManager.samples.count,
                        signalQuality: cameraManager.signalQuality,
                        contactState: cameraManager.contactState
                    )
                    
                    Text("Keep your finger steady on the rear camera + flash")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
                .padding(.vertical, 12)
            }
            .padding(.vertical, 20)
        }
        .onAppear {
            startRecording()
        }
        .onChange(of: cameraManager.isRecording) { _, isRecording in
            if !isRecording {
                // recording stopped early or naturally; UI will dismiss via onComplete callback
            }
        }
    }
    
    private func startRecording() {
        cameraManager.onRecordingComplete = { measurement in
            onComplete(measurement)
        }
        cameraManager.startRecording()
    }
    
    private func finishEarly() {
        cameraManager.stopRecording()
    }
    
    private func cancelRecording() {
        cameraManager.stopRecording()
        dismiss()
        onComplete(nil)
    }
}

#Preview {
    RecordingView(cameraManager: CameraManager()) { _ in }
}
