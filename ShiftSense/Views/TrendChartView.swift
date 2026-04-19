import Charts
import SwiftUI

struct TrendChartView: View {
  let records: [CheckInRecord]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Shift trend")
        .font(.headline)

      if records.isEmpty {
        Text("Run a few check-ins to view pulse and breathing trends across the shift.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } else {
        Chart {
          ForEach(records) { record in
            LineMark(
              x: .value("Time", record.timestamp),
              y: .value("BPM", record.pulse),
              series: .value("Metric", "Pulse")
            )
            .foregroundStyle(.red)
            .interpolationMethod(.catmullRom)

            PointMark(
              x: .value("Time", record.timestamp),
              y: .value("BPM", record.pulse)
            )
            .foregroundStyle(record.level.color)

            LineMark(
              x: .value("Time", record.timestamp),
              y: .value("BPM", record.breathing),
              series: .value("Metric", "Breathing")
            )
            .foregroundStyle(.blue)
            .interpolationMethod(.catmullRom)
          }
        }
        .chartForegroundStyleScale([
          "Pulse": Color.red,
          "Breathing": Color.blue
        ])
        .chartYAxisLabel("BPM / breaths·min⁻¹")
        .frame(height: 220)
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(Color(.secondarySystemBackground))
    )
  }
}
