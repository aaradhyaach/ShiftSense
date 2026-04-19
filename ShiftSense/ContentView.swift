//
//  ContentView.swift
//  ShiftSense
//

import SwiftUI

struct ContentView: View {
  var body: some View {
    NavigationStack {
      ShiftSenseHomeView()
    }
  }
}

struct ShiftSenseHomeView: View {
  @EnvironmentObject private var store: CheckInStore

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        headerSection
        shiftContextCard
        actionButtons
        TrendChartView(records: store.activeShiftRecords)
        shiftInsightsCard
        recentHistoryCard
        sustainabilityCard
      }
      .padding(24)
      .frame(maxWidth: 760, alignment: .leading)
      .frame(maxWidth: .infinity, alignment: .center)
    }
    .background(Color(.systemGroupedBackground).ignoresSafeArea())
    .navigationTitle("ShiftSense")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var headerSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Image(systemName: "cross.case.circle.fill")
        .font(.system(size: 44))
        .foregroundStyle(.blue)

      Text("ShiftSense")
        .font(.system(size: 34, weight: .bold, design: .rounded))

      Text("Clinician stress and recovery check-ins")
        .font(.title3.weight(.semibold))

      Text("A contactless wellness workflow that translates short camera-based scans into shift-aware insights, trends, and recovery actions.")
        .font(.body)
        .foregroundStyle(.secondary)
    }
  }

  private var shiftContextCard: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Shift context")
        .font(.headline)

      Picker("Current Shift", selection: $store.activeShift) {
        ForEach(ShiftPeriod.allCases) { shift in
          Text(shift.title).tag(shift)
        }
      }
      .pickerStyle(.segmented)

      HStack(spacing: 12) {
        HomeStatCard(
          title: "Check-ins",
          value: "\(store.activeShiftRecords.count)",
          tint: .blue
        )
        HomeStatCard(
          title: "Strained",
          value: "\(store.strainedCountThisShift)",
          tint: .red
        )
        HomeStatCard(
          title: "Elevated+",
          value: "\(store.elevatedOrStrainedCountThisShift)",
          tint: .orange
        )
      }

      if let latest = store.latestRecordThisShift {
        Text("Latest \(store.currentShiftTitle.lowercased()): \(latest.level.title) • \(latest.timestamp.formatted(date: .omitted, time: .shortened))")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } else {
        Text("No check-ins yet for this \(store.currentShiftTitle.lowercased()).")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(Color(.secondarySystemBackground))
    )
  }

  private var actionButtons: some View {
    VStack(spacing: 14) {
      NavigationLink {
        LiveVitalsExampleView()
      } label: {
        Text("Start Check-In")
          .font(.headline)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .tint(.blue)

      NavigationLink {
        RecoveryPlanView(level: store.latestRecordThisShift?.level ?? .awaiting,
                         insight: store.latestRecordThisShift?.aiInsight)
      } label: {
        Text("Open Recovery Plan")
          .font(.headline)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
      }
      .buttonStyle(.bordered)
      .controlSize(.large)
    }
  }

  private var shiftInsightsCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Shift-level interpretation")
        .font(.headline)

      if store.activeShiftRecords.isEmpty {
        Text("As check-ins accumulate, ShiftSense will surface whether strain is isolated or recurring within the same shift.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } else if store.strainedCountThisShift >= 3 {
        Text("This shift shows repeated strained check-ins. That pattern suggests cumulative physiologic load across workload periods, not a single isolated spike.")
          .font(.subheadline)
      } else if store.elevatedOrStrainedCountThisShift >= 2 {
        Text("This shift already shows multiple elevated states. Consider using the recovery plan earlier rather than waiting for strain to accumulate further.")
          .font(.subheadline)
      } else {
        Text("Current shift trend is limited, but continued check-ins will make workload patterns easier to interpret over time.")
          .font(.subheadline)
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(Color(.secondarySystemBackground))
    )
  }

  private var recentHistoryCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Recent history")
        .font(.headline)

      if store.recentRecords.isEmpty {
        Text("No saved check-ins yet.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } else {
        ForEach(Array(store.recentRecords.prefix(5))) { record in
          HStack(alignment: .top) {
            Circle()
              .fill(record.level.color)
              .frame(width: 10, height: 10)
              .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
              Text("\(record.level.title) • \(record.shiftName)")
                .font(.subheadline.weight(.semibold))
              Text("Pulse \(record.pulse) bpm • Breathing \(record.breathing)/min")
                .font(.subheadline)
                .foregroundStyle(.secondary)
              Text(record.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
          }

          if record.id != store.recentRecords.prefix(5).last?.id {
            Divider()
          }
        }
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(Color(.secondarySystemBackground))
    )
  }

  private var sustainabilityCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Why this is sustainable")
        .font(.headline)

      Label("Uses existing phone camera hardware instead of requiring extra wearables or charging accessories.", systemImage: "leaf")
      Label("Encourages low-resource recovery steps like breathing, hydration, micro-breaks, and re-checking.", systemImage: "figure.mind.and.body")
      Label("Tracks repeated strain across a shift so wellness support can happen earlier, before the burden compounds.", systemImage: "chart.line.uptrend.xyaxis")

      Text("In sustainable healthcare, supporting the workforce matters too. ShiftSense makes preventive check-ins easier to repeat during real clinical shifts.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .padding(.top, 4)
    }
    .font(.subheadline)
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(Color(.tertiarySystemBackground))
    )
  }
}

struct RecoveryPlanView: View {
  let level: WellnessLevel
  let insight: String?

  init(level: WellnessLevel = .awaiting, insight: String? = nil) {
    self.level = level
    self.insight = insight
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        Text(level.recoveryHeadline)
          .font(.system(size: 30, weight: .bold, design: .rounded))

        Text(level.recoveryIntro)
          .font(.body)
          .foregroundStyle(.secondary)

        if let insight, !insight.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Text("Latest interpretation")
              .font(.headline)

            Text(insight)
              .font(.subheadline)
          }
          .padding(18)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
              .fill(Color(.secondarySystemBackground))
          )
        }

        VStack(alignment: .leading, spacing: 16) {
          Text("Immediate reset")
            .font(.headline)

          RecoveryStepRow(number: "1", text: "Inhale gently for 4 seconds")
          RecoveryStepRow(number: "2", text: "Hold for 4 seconds")
          RecoveryStepRow(number: "3", text: "Exhale slowly for 6 seconds")
          RecoveryStepRow(number: "4", text: "Repeat for 60 seconds")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color(.secondarySystemBackground))
        )

        VStack(alignment: .leading, spacing: 16) {
          Text("Next 5–10 minutes")
            .font(.headline)

          RecoverySupportRow(icon: "drop.fill", title: "Hydrate", detail: "Take a few sips of water to create a full pause, not just a rushed reset.")
          RecoverySupportRow(icon: "eye.fill", title: "Visual break", detail: "Look away from the screen or nearby task surface for 20–30 seconds.")
          RecoverySupportRow(icon: "figure.walk", title: "Micro-movement", detail: "If workflow allows, stand, roll your shoulders, or take a short walk.")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color(.secondarySystemBackground))
        )

        VStack(alignment: .leading, spacing: 16) {
          Text("If strain is repeating this shift")
            .font(.headline)

          RecoverySupportRow(icon: "arrow.clockwise.circle", title: "Re-check after recovery", detail: "Run another 15-second scan after the reset to see if your signals are settling.")
          RecoverySupportRow(icon: "clock.arrow.circlepath", title: "Space out demanding tasks", detail: "When possible, avoid stacking another high-load task immediately after a strained check-in.")
          RecoverySupportRow(icon: "person.2.fill", title: "Escalate if needed", detail: "If multiple strained readings continue across the shift, consider a longer break or team support if workflow allows.")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color(.secondarySystemBackground))
        )

        VStack(alignment: .leading, spacing: 12) {
          Text("Sustainability connection")
            .font(.headline)

          Text("ShiftSense supports sustainable care delivery by helping clinicians use preventive, low-resource recovery steps before strain accumulates across a shift.")
            .font(.subheadline)
            .foregroundStyle(.secondary)

          Text("Because the workflow uses existing device hardware, it avoids the extra cost, waste, and maintenance burden of dedicated wearable programs.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color(.tertiarySystemBackground))
        )

        Text("For wellness and self-awareness only. Not intended for diagnosis or treatment.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      .padding(24)
      .frame(maxWidth: 760, alignment: .leading)
      .frame(maxWidth: .infinity, alignment: .center)
    }
    .background(Color(.systemGroupedBackground).ignoresSafeArea())
    .navigationTitle("Recovery Plan")
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct HomeStatCard: View {
  let title: String
  let value: String
  let tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      Text(value)
        .font(.title2.weight(.bold))
        .foregroundStyle(tint)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(tint.opacity(0.08))
    )
  }
}

private struct RecoveryStepRow: View {
  let number: String
  let text: String

  var body: some View {
    HStack(spacing: 12) {
      Text(number)
        .font(.headline.weight(.bold))
        .frame(width: 30, height: 30)
        .background(Circle().fill(Color.blue.opacity(0.12)))
        .foregroundStyle(.blue)

      Text(text)
        .font(.body)
    }
  }
}

private struct RecoverySupportRow: View {
  let icon: String
  let title: String
  let detail: String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: icon)
        .font(.headline)
        .foregroundStyle(.blue)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.subheadline.weight(.semibold))
        Text(detail)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  ContentView()
}
