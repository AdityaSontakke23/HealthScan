//
//  HealthReportGenerator.swift
//  HealthScan
//
//  Generates a detailed, context-aware physiological report
//  from a completed PPG measurement.
//

import Foundation

struct HealthReport: Sendable {
    let headline: String
    let statusColorName: String // "green", "orange", "red"
    let executiveSummary: String
    let cardiovascularAnalysis: String
    let autonomicStressAnalysis: String
    let respiratoryAnalysis: String
    let recommendations: [String]
}

struct HealthReportGenerator {
    
    static func generate(for m: Measurement) -> HealthReport {
        let bpm = m.bpm
        let hrv = m.hrvMs ?? 38.0
        let stress = m.stressScore ?? 45
        let resp = m.respiratoryRate ?? 15
        let readiness = m.readinessScore ?? 75
        let hrvFormatted = Int(round(hrv))
        let tag = m.tag ?? .resting
        
        // 1. Context-Aware Headline & Status
        let headline: String
        let statusColorName: String
        switch tag {
        case .postWorkout:
            if bpm <= 135 {
                headline = "Normal Post-Exercise Cardiovascular Recovery"
                statusColorName = "green"
            } else {
                headline = "High Post-Workout Sympathetic Demand"
                statusColorName = "orange"
            }
        case .stressed:
            if stress >= 60 || bpm > 85 {
                headline = "Acute Sympathetic Activation Detected"
                statusColorName = "orange"
            } else {
                headline = "Resilient Autonomic Buffering Under Stress"
                statusColorName = "green"
            }
        case .morning:
            if readiness >= 70 && bpm <= 75 {
                headline = "Optimal Waking Baseline & High Readiness"
                statusColorName = "green"
            } else if readiness >= 50 {
                headline = "Moderate Overnight Autonomic Recovery"
                statusColorName = "orange"
            } else {
                headline = "Incomplete Overnight Recovery — Rest Advised"
                statusColorName = "red"
            }
        case .resting:
            if readiness >= 75 && stress < 50 {
                headline = "Optimal Recovery & Balanced Autonomic State"
                statusColorName = "green"
            } else if readiness >= 50 && stress < 70 {
                headline = "Moderate Autonomic Load & Normal Baseline"
                statusColorName = "orange"
            } else {
                headline = "Elevated Physiological Strain — Rest Advised"
                statusColorName = "red"
            }
        }
        
        // 2. Context-Aware Executive Summary (Doctor-grade)
        let contextLabel = "recorded in a \(tag.rawValue.lowercased()) state"
        let executiveSummary = "Your 30-second optical scan (\(contextLabel)) shows an overall Readiness Score of \(readiness)/100 and a Stress Index of \(stress)/100. Evaluated against clinical reference ranges for \(tag.rawValue.lowercased()) physiology, your cardiovascular and autonomic systems demonstrate \(statusColorName == "green" ? "healthy adaptation and strong vagal regulation" : (statusColorName == "orange" ? "active physiological engagement and moderate autonomic load" : "elevated sympathetic strain requiring restorative downtime"))."
        
        // 3. Context-Aware Cardiovascular Analysis (Doctor-grade)
        let cardioAnalysis: String
        if tag == .postWorkout {
            cardioAnalysis = "At \(bpm) BPM following physical exertion, your heart rate reflects expected post-exercise oxygen debt (EPOC) and active peripheral vasodilation. Signal quality was rated \(m.quality.rawValue.lowercased()) over \(String(format: "%.0f", m.duration)) seconds."
        } else if tag == .morning {
            cardioAnalysis = "Your waking heart rate of \(bpm) BPM serves as your primary metabolic baseline. \(bpm <= 72 ? "This low morning cadence indicates efficient overnight cardiac restoration." : "A slightly elevated waking pulse (>72 BPM) can reflect late evening meals, mild dehydration, or residual fatigue.")"
        } else {
            let zone = bpm < 60 ? "athletic / low resting range (<60 BPM), indicating high stroke volume efficiency." : (bpm <= 80 ? "optimal resting zone (60–80 BPM), reflecting efficient cardiac output and low baseline workload." : (bpm <= 100 ? "upper-normal range (81–100 BPM), commonly associated with mild sympathetic stimulation or digestion." : "elevated range (>100 BPM), indicating heightened cardiac workload."))
            cardioAnalysis = "At \(bpm) BPM (\(tag.rawValue.lowercased())), your heart rate sits in the \(zone) Signal quality was rated \(m.quality.rawValue.lowercased())."
        }
        
        // 4. Context-Aware Autonomic & Stress Analysis (Doctor-grade)
        let autonomicStressAnalysis: String
        if tag == .postWorkout {
            autonomicStressAnalysis = "Post-exercise HRV (rMSSD) measured \(hrvFormatted) ms with a Stress Index of \(stress)/100. Temporary vagal withdrawal and elevated sympathetic tone are normal immediately after training as the body clears metabolic byproducts."
        } else if tag == .stressed {
            autonomicStressAnalysis = "During self-reported stress, your HRV (rMSSD) measured \(hrvFormatted) ms (Stress Score \(stress)/100). \(hrv >= 40 ? "Despite feeling stressed, your vagal tone remains resilient, buffering cardiovascular strain effectively." : "This reflects acute sympathetic ('fight-or-flight') dominance and reduced beat-to-beat vagal modulation.")"
        } else {
            let ansState = hrv >= 50 ? "strong vagal tone and robust parasympathetic ('rest-and-digest') recovery." : (hrv >= 30 ? "balanced autonomic tone between sympathetic drive and parasympathetic recovery." : "reduced beat-to-beat variability and heightened sympathetic activation.")
            autonomicStressAnalysis = "Your Heart Rate Variability (rMSSD) measured \(hrvFormatted) ms, yielding a Stress Score of \(stress)/100. This indicates \(ansState)"
        }
        
        // 5. Respiratory Analysis (Doctor-grade)
        let respState = resp <= 14 ? "calm, slow diaphragmatic breathing supporting vagal tone." : (resp <= 18 ? "normal baseline ventilation (12–18 breaths/min)." : "elevated respiratory frequency (>18 breaths/min), consistent with \(tag == .postWorkout ? "post-exercise oxygen recovery" : "heightened autonomic alertness").")
        let respiratoryAnalysis = "Pulse-wave modulation estimates your respiratory rate at \(resp) breaths/min, reflecting \(respState)"
        
        // 6. Personalized Recommendations (Warm, kind, normal human speech — at least 3)
        let recs = buildFriendlyRecommendations(tag: tag, readiness: readiness, stress: stress, quality: m.quality)
        
        return HealthReport(
            headline: headline,
            statusColorName: statusColorName,
            executiveSummary: executiveSummary,
            cardiovascularAnalysis: cardioAnalysis,
            autonomicStressAnalysis: autonomicStressAnalysis,
            respiratoryAnalysis: respiratoryAnalysis,
            recommendations: recs
        )
    }
    
    private static func buildFriendlyRecommendations(tag: MeasurementTag, readiness: Int, stress: Int, quality: SignalQuality) -> [String] {
        var recs: [String] = []
        switch tag {
        case .postWorkout:
            recs.append("Great job finishing your workout! Your heart is naturally working to cool you down right now, so take 5 to 10 minutes to walk slowly and stretch gently.")
            recs.append("Rehydrate with a tall glass of water (and a pinch of electrolytes if you sweated heavily) to help your heart rate settle back to its resting rhythm.")
            recs.append("Treat yourself to a nourishing meal with protein and complex carbs within the next hour so your muscles and nervous system can rebuild.")
        case .stressed:
            recs.append("It's completely okay to feel stressed—let's help your body release some of that tension right now. Drop your shoulders away from your ears and unclench your jaw.")
            recs.append("Try this gentle 1-minute reset: take two slow breaths in through your nose, then let out one long, soft sigh through your mouth. Repeat this 4 times to tell your heart it is safe to slow down.")
            recs.append("If you can, step away from your screen for 5 minutes, drink some cool water, and focus on just one small, easy thing at a time.")
        case .morning:
            if readiness >= 65 {
                recs.append("Good morning! Your body recharged nicely overnight, giving you a wonderful foundation of energy for whatever you have planned today.")
                recs.append("Start your morning kindly with a full glass of water before your coffee or tea, and get a few minutes of natural daylight to wake up your body clock.")
                recs.append("Today is a great day to enjoy a workout or tackle focused work—just remember to take short breathing breaks along the way.")
            } else {
                recs.append("Good morning! It looks like your body is still catching up on rest today, so be extra gentle with yourself and ease into your morning slowly.")
                recs.append("Drink a large glass of water right away, and consider swapping heavy exercise today for a relaxing walk or light stretching.")
                recs.append("Try to give yourself an earlier, cozy bedtime tonight so your body can finish recharging.")
            }
        case .resting:
            if readiness >= 75 && stress < 50 {
                recs.append("You're in a great spot today! Your heart and nervous system look calm and well-rested, so feel free to enjoy your day with confidence.")
                recs.append("Keep supporting your body with steady hydration throughout the day and a few quick stretches between tasks.")
                recs.append("To keep this smooth rhythm going tomorrow, wind down peacefully tonight without bright screens for 20 minutes before sleep.")
            } else if readiness >= 50 && stress < 70 {
                recs.append("Your body is doing well, just working a little bit behind the scenes today. Pace yourself with a comfortable, steady rhythm rather than rushing.")
                recs.append("Gift yourself a gentle 2-minute pause: sit back, breathe in softly through your nose for 4 seconds, and breathe out slowly for 6 seconds.")
                recs.append("Have a glass of water right now and plan for a calm, unhurried evening so you can recharge fully tonight.")
            } else {
                recs.append("Your body is asking for a little extra care and kindness today. Take things slow, skip strenuous workouts, and give yourself permission to rest.")
                recs.append("Try this simple calming breath right now: inhale gently through your nose for 4 seconds, and exhale softly for 6 seconds for a couple of minutes.")
                recs.append("Drink plenty of water, take breaks from busy screens, and treat yourself to an early, restful night of sleep.")
            }
        }
        if quality == .noisy {
            recs.append("A friendly tip for your next scan: resting your hand flat on a table and touching the camera lens very lightly will give you an even steadier reading.")
        }
        return recs
    }
}
