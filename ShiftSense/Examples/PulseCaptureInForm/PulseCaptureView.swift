//
//  PulseCaptureView.swift
//  ShiftSense
//

import AVFoundation
import Combine
import SmartSpectraSwiftSDK
import SwiftUI
import UIKit

struct PulseCaptureReading: Equatable {
  let bpm: Int
  let capturedAt: Date

  var bpmString: String { String(bpm) }
  var formattedBpm: String { "\(bpm) BPM" }
  var formattedTimestamp: String {
    capturedAt.formatted(date: .abbreviated, time: .shortened)
  }
}

struct PulseCaptureView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var model: PulseCaptureSession

  private let onComplete: (PulseCaptureReading) -> Void

  init(initialReading: PulseCaptureReading?, onComplete: @escaping (PulseCaptureReading) -> Void) {
    _model = StateObject(wrappedValue: PulseCaptureSession(initialReading: initialReading))
    self.onComplete = onComplete
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Color(.systemGroupedBackground)
          .ignoresSafeArea()

        VStack(spacing: 18) {
          CameraPreview(image: model.previewImage)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)

          VStack(spacing: 8) {
            if let averagePulse = model.averageConfidentPulse {
              Text("Pulse estimate: \(averagePulse) BPM")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.green)
            } else if let livePulse = model.livePulse {
              Text("Measuring pulse: \(livePulse) BPM")
                .font(.title3.weight(.semibold))
            }

            Text(model.statusMessage)
              .multilineTextAlignment(.center)
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }

          if let error = model.errorMessage {
            Label(error, systemImage: "exclamationmark.triangle.fill")
              .font(.footnote)
              .foregroundStyle(.yellow)
          }

          Button {
            model.toggleRecording()
          } label: {
            Label(
              model.isRecording ? "Stop Scan" : "Start Scan",
              systemImage: model.isRecording ? "stop.circle" : "play.circle"
            )
            .font(.headline)
            .labelStyle(.titleAndIcon)
          }
          .buttonStyle(.borderedProminent)
          .tint(model.isRecording ? .red : .blue)
          .disabled(!model.canToggleRecording)
        }
        .frame(maxWidth: 520)
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .top)
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            model.teardown()
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save Check-In") {
            guard let reading = model.commitMeasurement() else { return }
            onComplete(reading)
            dismiss()
          }
          .disabled(!model.canFinalize)
        }
      }
      .navigationTitle("Quick Check-In")
      .navigationBarTitleDisplayMode(.inline)
    }
    .onAppear { model.prepareSession() }
    .onDisappear { model.teardown() }
  }
}

private struct CameraPreview: View {
  let image: UIImage?

  var body: some View {
    GeometryReader { geometry in
      let side = min(geometry.size.width, geometry.size.height)

      ZStack {
        RoundedRectangle(cornerRadius: 16)
          .fill(.secondary.opacity(0.12))

        if let uiImage = image {
          Image(uiImage: uiImage)
            .resizable()
            .scaledToFill()
            .frame(width: side, height: side)
            .clipped()
        } else {
          ProgressView("Preparing camera...")
            .padding()
        }
      }
      .frame(width: side, height: side)
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .strokeBorder(.white.opacity(0.2), lineWidth: 1)
      )
      .position(x: geometry.size.width / 2, y: side / 2)
    }
    .aspectRatio(1, contentMode: .fit)
  }
}

@MainActor
private final class PulseCaptureSession: ObservableObject {
  @Published var previewImage: UIImage?
  @Published var statusMessage = "Ready for check-in."
  @Published var livePulse: Int?
  @Published var isRecording = false
  @Published var errorMessage: String?

  @Published var confidentReadings: [Presage_Physiology_MeasurementWithConfidence] = []
  var averageConfidentPulse: Int? {
    guard !confidentReadings.isEmpty else { return nil }
    let sum = confidentReadings.reduce(0.0) { partial, reading in
      partial + Double(reading.value)
    }
    let avg = sum / Double(confidentReadings.count)
    return Int(avg.rounded())
  }

  @Published private(set) var measurement: PulseCaptureReading?
  var canFinalize: Bool { measurement != nil && !isRecording }
  var canToggleRecording: Bool { isRecording || vitalsProcessor.lastStatusCode == .ok }

  private let smartSpectra = SmartSpectraSwiftSDK.shared
  private let vitalsProcessor = SmartSpectraVitalsProcessor.shared
  private var cancellables: Set<AnyCancellable> = []
  private var hasActiveSession = false
  private let maxConfidentReadings: Int = 50

  init(initialReading: PulseCaptureReading?) {
    self.measurement = initialReading
    bindStreams()
  }

  func prepareSession() {
    smartSpectra.setSmartSpectraMode(.continuous)
    smartSpectra.setCameraPosition(.front)
    smartSpectra.setImageOutputEnabled(true)
    smartSpectra.resetMetrics()
    vitalsProcessor.startProcessing()
    statusMessage = "Position your face in the center of the frame."
  }

  func toggleRecording() {
    if isRecording {
      stopRecording()
    } else {
      guard canToggleRecording else { return }
      startRecording()
    }
  }

  func commitMeasurement() -> PulseCaptureReading? {
    measurement
  }

  func teardown() {
    stopRecording()
    vitalsProcessor.stopProcessing()
    smartSpectra.resetMetrics()
  }

  private func bindStreams() {
    vitalsProcessor.$imageOutput
      .receive(on: RunLoop.main)
      .sink { [weak self] image in
        self?.previewImage = image
      }
      .store(in: &cancellables)

    smartSpectra.$metricsBuffer
      .receive(on: RunLoop.main)
      .compactMap { buffer -> Presage_Physiology_MeasurementWithConfidence? in
        guard let buffer else { return nil }
        guard let latest = buffer.pulse.rate.last else { return nil }
        return latest
      }
      .sink { [weak self] measurement in
        guard let self else { return }
        livePulse = Int(measurement.value.rounded())
        if measurement.confidence > 0 {
          insertConfidentReading(measurement)
        }
      }
      .store(in: &cancellables)

    vitalsProcessor.$statusHint
      .receive(on: RunLoop.main)
      .sink { [weak self] hint in
        guard let self else { return }
        let trimmed = hint.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
          statusMessage = trimmed
        }
      }
      .store(in: &cancellables)

    vitalsProcessor.$isRecording
      .receive(on: RunLoop.main)
      .sink { [weak self] recording in
        guard let self else { return }
        isRecording = recording
        if !recording {
          handleRecordingStopped()
        }
      }
      .store(in: &cancellables)
  }

  private func insertConfidentReading(_ reading: Presage_Physiology_MeasurementWithConfidence) {
    if confidentReadings.count < maxConfidentReadings {
      confidentReadings.append(reading)
      return
    }

    if let minIndex = confidentReadings.enumerated().min(by: { lhs, rhs in
      lhs.element.confidence < rhs.element.confidence
    })?.offset,
      reading.confidence > confidentReadings[minIndex].confidence
    {
      confidentReadings[minIndex] = reading
    }
  }

  private func startRecording() {
    errorMessage = nil
    statusMessage = "Initializing scan..."
    smartSpectra.resetMetrics()

    livePulse = nil
    measurement = nil
    confidentReadings.removeAll()
    hasActiveSession = true
    vitalsProcessor.startRecording()
    statusMessage = "Hold steady while we measure."
  }

  private func stopRecording() {
    guard vitalsProcessor.isRecording else { return }
    vitalsProcessor.stopRecording()
  }

  private func handleRecordingStopped() {
    guard hasActiveSession else { return }
    hasActiveSession = false

    guard let bpm = averageConfidentPulse, bpm > 0 else {
      measurement = nil
      statusMessage = "No confident pulse reading detected. Try again."
      errorMessage = "No confident pulse was captured during this check-in."
      return
    }

    measurement = PulseCaptureReading(bpm: bpm, capturedAt: Date())
    statusMessage = "Check-in complete."
    errorMessage = nil
  }
}
