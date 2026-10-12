//
//  BPMPreviewRing.swift
//  HealthScan
//
//  Circular camera preview with live BPM display and recording progress ring.
//

import SwiftUI
@preconcurrency import AVFoundation

struct BPMPreviewRing: View {
    let session: AVCaptureSession?
    let bpm: Int?
    let progress: Double
    let quality: SignalQuality
    let accent: Color
    let glow: Color
    
    private var clampedProgress: Double {
        max(0, min(1, progress))
    }
    
    private var bpmText: String {
        if let bpm {
            return "\(bpm)"
        } else {
            return "--"
        }
    }
    
    var body: some View {
        ZStack {
            // Live preview with a soft tint so users see exactly which camera/flash to cover
            CameraPreviewView(session: session)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.45),
                            Color.red.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(Circle())
            
            // Base ring
            Circle()
                .stroke(Color.white.opacity(0.22), lineWidth: 12)
            
            // Progress ring (starts when countdown begins)
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            accent,
                            glow,
                            accent
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: clampedProgress)
            
            // BPM readout
            VStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: .repeating, value: bpm != nil)
                
                Text(bpmText)
                    .font(.system(size: 58, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                
                Text("bpm")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
        }
        .frame(width: 280, height: 280)
        .shadow(color: glow.opacity(0.35), radius: 18, y: 10)
    }
}

#Preview {
    BPMPreviewRing(
        session: nil,
        bpm: 72,
        progress: 0.45,
        quality: .good,
        accent: Color(red: 1.0, green: 0.51, blue: 0.0),
        glow: Color(red: 1.0, green: 0.72, blue: 0.11)
    )
    .padding()
    .background(Color.blue)
}
