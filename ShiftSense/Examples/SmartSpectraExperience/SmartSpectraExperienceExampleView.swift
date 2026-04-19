//
//  SmartSpectraExperienceExampleView.swift
//  ShiftSense
//

import AVFoundation
import SmartSpectraSwiftSDK
import SwiftUI

struct SmartSpectraExperienceExampleView: View {
  @ObservedObject private var sdk = SmartSpectraSwiftSDK.shared

  private enum Config {
    static let mode: SmartSpectraMode = .continuous
    static let camera: AVCaptureDevice.Position = .front
    static let measurementDuration: Double = 15
    static let showsBuiltInControls = true
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        introSection
        guidedCheckInCard
        metricsSection
      }
      .padding(24)
      .frame(maxWidth: 640)
      .frame(maxWidth: .infinity)
    }
    .background(Color(.systemGroupedBackground).ignoresSafeArea())
    .navigationTitle("ShiftSense Guided Check-In")
    .navigationBarTitleDisplayMode(.inline)
    .cameraPermissionGate()
    .onAppear(perform: configureSdk)
  }

  private var introSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Guided wellness check-in")
        .font(.title2.weight(.semibold))

      Text("This guided flow walks the user through a brief contactless check-in and returns pulse and breathing summaries.")
        .font(.callout)
        .foregroundStyle(.secondary)
    }
  }

  private var guidedCheckInCard: some View {
    SmartSpectraView()
      .frame(maxWidth: .infinity)
      .frame(minHeight: 420)
      .background(
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(Color(.secondarySystemBackground))
      )
      .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
      .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
  }

  @ViewBuilder
  private var metricsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Latest check-in summary")
        .font(.title3.weight(.semibold))

      if let metrics = sdk.metricsBuffer {
        if let pulse = metrics.pulse.rate.last {
          let bpm = Int(pulse.value.rounded())
          let confidence = Int(pulse.confidence.rounded())
          Text("Pulse: \(bpm) bpm (confidence \(confidence))")
        }

        if let breathing = metrics.breathing.rate.last {
          let breathsPerMinute = Int(breathing.value.rounded())
          Text("Breathing: \(breathsPerMinute) breaths/min")
        }

        if metrics.hasMetadata {
          Text("Updated: \(metrics.metadata.uploadTimestamp)")
            .foregroundStyle(.secondary)
        }

        if metrics.pulse.rate.last == nil, metrics.breathing.rate.last == nil {
          Text("No summary metrics available yet.")
            .foregroundStyle(.secondary)
        }
      } else {
        Text("Start a guided check-in to view pulse and breathing summaries here.")
          .foregroundStyle(.secondary)
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(Color(.secondarySystemBackground))
    )
  }

  private func configureSdk() {
    sdk.setSmartSpectraMode(Config.mode)
    sdk.setCameraPosition(Config.camera)
    sdk.setMeasurementDuration(Config.measurementDuration)
    sdk.showControlsInScreeningView(Config.showsBuiltInControls)
  }
}

#Preview {
  NavigationStack {
    SmartSpectraExperienceExampleView()
  }
}
