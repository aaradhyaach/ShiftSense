//
//  LiveVitalsExampleView.swift
//  ShiftSense
//

import AVFoundation
import Combine
import SmartSpectraSwiftSDK
import SwiftUI
import UIKit

struct LiveVitalsExampleView: View {
  @EnvironmentObject private var store: CheckInStore
  @StateObject private var session = LiveVitalsSession()

  @State private var showRecoveryPlan = false
  @State private var latestInsight = ""
  @State private var isGeneratingInsight = false

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        shiftContextCard
        CameraCard(
          image: session.previewImage,
          guidanceText: session.guidanceText
        )

        VStack(spacing: 12) {
          StatePill(
            text: session.stateText,
            color: session.stateColor
          )

          Button(action: session.toggleRecording) {
            Text(session.isRecording ? "Stop Scan" : "Start 15-Second Scan")
              .font(.headline)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 16)
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .tint(.blue)
          .disabled(!session.canToggleRecording)

          if session.isRecording {
            CountdownCard(secondsRemaining: session.secondsRemaining)
          }
        }

        if session.isRecording {
          MeasuringStatusCard()
        } else {
          ResultSummaryCard(
            pulseRate: session.finalPulseRate,
            breathingRate: session.finalBreathingRate,
            level: session.currentLevel,
            aiInsight: latestInsight,
            isGeneratingInsight: isGeneratingInsight,
            strainedCountThisShift: store.strainedCountThisShift
          )
        }

        if !session.isRecording {
          Button {
            showRecoveryPlan = true
          } label: {
            Text("Open Recovery Plan")
              .font(.headline)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 14)
          }
          .buttonStyle(.bordered)
          .controlSize(.large)
        }

        if !store.activeShiftRecords.isEmpty {
          TrendChartView(records: store.activeShiftRecords)
        }

        SustainabilityFooterCard()

        Text("For wellness and self-awareness only.")
          .font(.footnote)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(20)
      .frame(maxWidth: 760)
      .frame(maxWidth: .infinity)
    }
    .background(Color(.systemGroupedBackground).ignoresSafeArea())
    .navigationTitle("Check-In")
    .navigationBarTitleDisplayMode(.inline)
    .cameraPermissionGate()
    .task { session.prepare() }
    .onDisappear { session.teardown() }
    .onChange(of: session.completedScanID) { _, completedScanID in
      guard completedScanID != nil else { return }
      Task {
        await handleCompletedScan()
      }
    }
    .navigationDestination(isPresented: $showRecoveryPlan) {
      RecoveryPlanView(level: session.currentLevel, insight: latestInsight)
    }
  }

  private var shiftContextCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Current shift")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)

      HStack {
        Text(store.currentShiftTitle)
          .font(.headline)
        Spacer()
        Text("\(store.activeShiftRecords.count) saved check-ins")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Color(.secondarySystemBackground))
    )
  }

  private func handleCompletedScan() async {
    guard session.hasResults else { return }

    isGeneratingInsight = true
    let currentLevel = session.currentLevel
    let predictedStrainedCount = store.strainedCountThisShift + (currentLevel == .strained ? 1 : 0)

    let aiInsight = await GeminiInsightService.generateInsight(
      pulse: session.finalPulseRate,
      breathing: session.finalBreathingRate,
      level: currentLevel,
      shiftName: store.currentShiftTitle,
      strainedCountThisShift: predictedStrainedCount
    )

    latestInsight = aiInsight
    store.addRecord(
      pulse: session.finalPulseRate,
      breathing: session.finalBreathingRate,
      level: currentLevel,
      aiInsight: aiInsight
    )
    isGeneratingInsight = false

    if currentLevel == .strained {
      showRecoveryPlan = true
    }
  }
}

private struct CameraCard: View {
  let image: UIImage?
  let guidanceText: String

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("15-second wellness check")
        .font(.headline)

      ZStack(alignment: .bottomLeading) {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(Color.black.opacity(0.94))
          .frame(height: 320)

        if let frame = image {
          Image(uiImage: frame)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
          VStack(spacing: 12) {
            ProgressView()
            Text("Initializing camera...")
              .foregroundStyle(.white.opacity(0.9))
              .font(.subheadline)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        Text(guidanceText)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.white)
          .padding(.horizontal, 14)
          .padding(.vertical, 10)
          .background(.ultraThinMaterial)
          .clipShape(Capsule())
          .padding(16)
      }
      .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
  }
}

private struct CountdownCard: View {
  let secondsRemaining: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("Time remaining")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)

        Spacer()

        Text("\(secondsRemaining)s")
          .font(.title3.weight(.bold))
          .monospacedDigit()
      }

      ProgressView(value: Double(15 - secondsRemaining), total: 15)
        .tint(.blue)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Color(.secondarySystemBackground))
    )
  }
}

private struct MeasuringStatusCard: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 12) {
        ProgressView()
        Text("Measuring")
          .font(.headline)
      }

      Text("Hold still, keep your face centered, and avoid speaking during the scan.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(Color(.secondarySystemBackground))
    )
  }
}

private struct ResultSummaryCard: View {
  let pulseRate: Int
  let breathingRate: Int
  let level: WellnessLevel
  let aiInsight: String
  let isGeneratingInsight: Bool
  let strainedCountThisShift: Int

  private var hasResults: Bool {
    pulseRate > 0 || breathingRate > 0
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text(hasResults ? "Your Check-In Summary" : "No check-in yet")
        .font(.headline)

      HStack {
        VStack(alignment: .leading, spacing: 6) {
          Text(level.title)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(level.color)

          Text(level.subtitle(hasResults: hasResults))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Spacer()
      }

      HStack(spacing: 12) {
        MetricCard(
          title: "Pulse",
          value: hasResults ? "\(pulseRate)" : "--",
          unit: "bpm",
          icon: "heart.fill",
          tint: .red
        )

        MetricCard(
          title: "Breathing",
          value: hasResults ? "\(breathingRate)" : "--",
          unit: "breaths/min",
          icon: "lungs.fill",
          tint: .blue
        )
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("Clinical-style interpretation")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)

        if isGeneratingInsight {
          HStack(spacing: 10) {
            ProgressView()
            Text("Generating personalized interpretation...")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
        } else if !aiInsight.isEmpty {
          Text(aiInsight)
            .font(.body)
        } else {
          Text(level.defaultInsight(
            pulse: pulseRate,
            breathing: breathingRate,
            strainedCountThisShift: strainedCountThisShift,
            shiftName: "current"
          ))
          .font(.body)
        }
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("Recommended next step")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)

        Text(level.recommendation())
          .font(.body)
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(Color(.secondarySystemBackground))
    )
  }
}

private struct MetricCard: View {
  let title: String
  let value: String
  let unit: String
  let icon: String
  let tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(title, systemImage: icon)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)

      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text(value)
          .font(.title2.weight(.bold))
          .foregroundStyle(.primary)

        Text(unit)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(tint.opacity(0.08))
    )
  }
}

private struct StatePill: View {
  let text: String
  let color: Color

  var body: some View {
    Text(text)
      .font(.subheadline.weight(.semibold))
      .foregroundStyle(color)
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(color.opacity(0.12))
      .clipShape(Capsule())
  }
}

private struct SustainabilityFooterCard: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Sustainable by design")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)

      Text("ShiftSense uses the existing device camera rather than requiring dedicated wearables, charging routines, or extra hardware procurement.")
        .font(.footnote)
        .foregroundStyle(.secondary)

      Text("By tracking repeated strain across a shift and encouraging early recovery actions, the app supports a more sustainable clinical workforce, not just a single reading.")
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Color(.tertiarySystemBackground))
    )
  }
}

@MainActor
final class LiveVitalsSession: ObservableObject {
  @Published var previewImage: UIImage?
  @Published var statusHint: String?
  @Published var isRecording = false

  @Published var finalPulseRate: Int = 0
  @Published var finalBreathingRate: Int = 0
  @Published var secondsRemaining: Int = 15
  @Published var completedScanID: UUID?

  private let smartSpectra = SmartSpectraSwiftSDK.shared
  private let vitalsProcessor = SmartSpectraVitalsProcessor.shared
  private var cancellables: Set<AnyCancellable> = []
  private var isProcessorActive = false

  private var currentPulseReadings: [Int] = []
  private var currentBreathingReadings: [Int] = []
  private var countdownTimer: Timer?

  init() {
    bindStreams()
  }

  var hasResults: Bool {
    finalPulseRate > 0 || finalBreathingRate > 0
  }

  var currentLevel: WellnessLevel {
    WellnessLevel.from(pulse: finalPulseRate, breathing: finalBreathingRate)
  }

  var canToggleRecording: Bool {
    if isRecording { return true }
    guard isProcessorActive else { return false }
    return vitalsProcessor.lastStatusCode == .ok
  }

  var stateText: String {
    if isRecording {
      return "Measuring"
    }
    if hasResults {
      return currentLevel.title
    }
    return "Ready"
  }

  var stateColor: Color {
    if isRecording { return .blue }
    return currentLevel.color
  }

  var guidanceText: String {
    if isRecording {
      if secondsRemaining <= 4 {
        return "Almost done"
      } else if secondsRemaining <= 9 {
        return "Keep face centered"
      } else {
        return "Hold still"
      }
    }

    let hint = statusHint?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if hint.localizedCaseInsensitiveContains("face is not centered") {
      return "Center face"
    }
    if hint.localizedCaseInsensitiveContains("lighting") {
      return "Improve lighting"
    }
    return "Ready"
  }

  func prepare() {
    guard !isProcessorActive else { return }

    smartSpectra.setSmartSpectraMode(.continuous)
    smartSpectra.setCameraPosition(.front)
    smartSpectra.setMeasurementDuration(15)
    smartSpectra.setImageOutputEnabled(true)
    smartSpectra.resetMetrics()

    vitalsProcessor.startProcessing()
    isProcessorActive = true
  }

  func toggleRecording() {
    guard isProcessorActive else { return }
    if isRecording {
      stopRecording()
    } else {
      startRecording()
    }
  }

  func teardown() {
    stopCountdown()
    stopRecording()
    guard isProcessorActive else { return }

    vitalsProcessor.stopProcessing()
    smartSpectra.resetMetrics()
    isProcessorActive = false
  }

  private func startRecording() {
    smartSpectra.resetMetrics()
    finalPulseRate = 0
    finalBreathingRate = 0
    currentPulseReadings = []
    currentBreathingReadings = []
    secondsRemaining = 15
    completedScanID = nil
    startCountdown()
    vitalsProcessor.startRecording()
  }

  private func stopRecording() {
    stopCountdown()
    guard vitalsProcessor.isRecording else { return }
    vitalsProcessor.stopRecording()
  }

  private func startCountdown() {
    stopCountdown()

    countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
      guard let self else {
        timer.invalidate()
        return
      }

      if self.secondsRemaining > 1 {
        self.secondsRemaining -= 1
      } else {
        self.secondsRemaining = 0
        timer.invalidate()
        self.countdownTimer = nil
        if self.isRecording {
          self.stopRecording()
        }
      }
    }
  }

  private func stopCountdown() {
    countdownTimer?.invalidate()
    countdownTimer = nil
  }

  private func summarize(_ values: [Int]) -> Int {
    let filtered = values.filter { $0 > 0 }
    guard !filtered.isEmpty else { return 0 }
    let sum = filtered.reduce(0, +)
    return Int((Double(sum) / Double(filtered.count)).rounded())
  }

  private func bindStreams() {
    vitalsProcessor.$imageOutput
      .receive(on: RunLoop.main)
      .sink { [weak self] image in
        self?.previewImage = image
      }
      .store(in: &cancellables)

    vitalsProcessor.$statusHint
      .receive(on: RunLoop.main)
      .sink { [weak self] hint in
        self?.statusHint = hint
      }
      .store(in: &cancellables)

    vitalsProcessor.$isRecording
      .receive(on: RunLoop.main)
      .sink { [weak self] recording in
        guard let self else { return }

        let wasRecording = self.isRecording
        self.isRecording = recording

        if wasRecording && !recording {
          self.stopCountdown()
          self.finalPulseRate = self.summarize(self.currentPulseReadings)
          self.finalBreathingRate = self.summarize(self.currentBreathingReadings)
          self.completedScanID = UUID()
        }
      }
      .store(in: &cancellables)

    smartSpectra.$metricsBuffer
      .receive(on: RunLoop.main)
      .sink { [weak self] buffer in
        guard let self, let buffer, self.isRecording else { return }

        if let latestPulse = buffer.pulse.rate.last {
          let rate = max(0, Int(latestPulse.value.rounded()))
          if rate > 0 {
            self.currentPulseReadings.append(rate)
          }
        }

        if let latestBreathing = buffer.breathing.rate.last {
          let rate = max(0, Int(latestBreathing.value.rounded()))
          if rate > 0 {
            self.currentBreathingReadings.append(rate)
          }
        }
      }
      .store(in: &cancellables)
  }
}
