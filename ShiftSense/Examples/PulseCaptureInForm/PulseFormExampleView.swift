//
//  PulseFormExampleView.swift
//  ShiftSense
//

import SwiftUI

struct PulseFormExampleView: View {
  @Environment(\.scenePhase) private var scenePhase
  @State private var latestReading: PulseCaptureReading?
  @State private var isPresentingCapture = false
  @State private var cameraStatus = CameraPermission.status()
  @State private var captureDetent: PresentationDetent = .large
  @State private var pulseFieldValue = ""

  var body: some View {
    Form {
      introSection

      Section("Check-In Record") {
        ReadOnlyMeasurementField(
          title: "Pulse",
          value: pulseFieldValue,
          unit: "bpm",
          placeholder: "Tap Start Check-In to save a pulse reading"
        )

        Text("The measurement is filled after you save a completed check-in.")
          .font(.footnote)
          .foregroundStyle(.secondary)
          .padding(.top, 4)
      }

      Section("Quick Check-In") {
        Button {
          captureDetent = .large
          isPresentingCapture = true
        } label: {
          Label {
            Text("Start Check-In")
              .fontWeight(.semibold)
          } icon: {
            Image(systemName: "camera.aperture")
              .symbolRenderingMode(.monochrome)
              .foregroundStyle(.white)
          }
          .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .frame(maxWidth: .infinity, alignment: .center)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .disabled(!isCameraCaptureAvailable)

        if cameraStatus == .denied || cameraStatus == .restricted {
          Text("Enable camera access in Settings to run a check-in.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }

      if let reading = latestReading {
        Section("Last Check-In") {
          LabeledContent("Pulse") {
            Text(reading.formattedBpm)
          }
          LabeledContent("Collected") {
            Text(reading.formattedTimestamp)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .navigationTitle("ShiftSense Check-In")
    .navigationBarTitleDisplayMode(.inline)
    .cameraPermissionGate()
    .sheet(isPresented: $isPresentingCapture) {
      PulseCaptureView(initialReading: latestReading) { reading in
        latestReading = reading
        pulseFieldValue = reading.bpmString
      }
      .presentationDetents([.large], selection: $captureDetent)
      .presentationDragIndicator(.hidden)
    }
    .onChange(of: scenePhase, initial: false) { _, newPhase in
      guard newPhase == .active else { return }
      cameraStatus = CameraPermission.status()
    }
    .onChange(of: latestReading, initial: true) { _, reading in
      pulseFieldValue = reading?.bpmString ?? ""
    }
  }
}

private extension PulseFormExampleView {
  var introSection: some View {
    Section {
      VStack(alignment: .leading, spacing: 8) {
        Text("Capture a quick wellness reading")
          .font(.headline)
        Text("Launch a short contactless check-in and save the pulse reading into this record.")
          .font(.callout)
          .foregroundStyle(.secondary)
      }
      .padding(.vertical, 4)
    }
  }

  var isCameraCaptureAvailable: Bool {
    switch cameraStatus {
    case .denied, .restricted:
      false
    default:
      true
    }
  }
}

private struct ReadOnlyMeasurementField: View {
  let title: String
  let value: String
  let unit: String?
  let placeholder: String

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.footnote)
        .foregroundStyle(.secondary)

      Text(displayValue)
        .font(.body)
        .foregroundStyle(value.isEmpty ? .secondary : .primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .strokeBorder(Color(.separator))
        )
        .background(
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(.systemBackground))
        )
    }
  }

  private var displayValue: String {
    if value.isEmpty {
      return placeholder
    }
    if let unit, !unit.isEmpty {
      return "\(value) \(unit)"
    }
    return value
  }
}

#Preview {
  NavigationStack {
    PulseFormExampleView()
  }
}
