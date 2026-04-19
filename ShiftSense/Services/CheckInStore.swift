import Foundation
import Combine

@MainActor
final class CheckInStore: ObservableObject {
  @Published var records: [CheckInRecord] = []
  @Published var activeShift: ShiftPeriod = .day {
    didSet {
      saveShiftPreference()
    }
  }

  private let recordsKey = "ShiftSense.records"
  private let shiftKey = "ShiftSense.activeShift"

  init() {
    load()
  }

  var currentShiftId: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return "\(formatter.string(from: Date()))-\(activeShift.rawValue)"
  }

  var currentShiftTitle: String {
    activeShift.title
  }

  var activeShiftRecords: [CheckInRecord] {
    records
      .filter { $0.shiftId == currentShiftId }
      .sorted { $0.timestamp < $1.timestamp }
  }

  var recentRecords: [CheckInRecord] {
    records.sorted { $0.timestamp > $1.timestamp }
  }

  var strainedCountThisShift: Int {
    activeShiftRecords.filter { $0.level == .strained }.count
  }

  var elevatedOrStrainedCountThisShift: Int {
    activeShiftRecords.filter { $0.level == .elevated || $0.level == .strained }.count
  }

  var latestRecordThisShift: CheckInRecord? {
    activeShiftRecords.last
  }

  func addRecord(
    pulse: Int,
    breathing: Int,
    level: WellnessLevel,
    aiInsight: String
  ) {
    let record = CheckInRecord(
      pulse: pulse,
      breathing: breathing,
      level: level,
      shiftId: currentShiftId,
      shiftName: activeShift.title,
      aiInsight: aiInsight
    )

    records.append(record)
    save()
  }

  private func save() {
    if let data = try? JSONEncoder().encode(records) {
      UserDefaults.standard.set(data, forKey: recordsKey)
    }
  }

  private func saveShiftPreference() {
    UserDefaults.standard.set(activeShift.rawValue, forKey: shiftKey)
  }

  private func load() {
    if let rawShift = UserDefaults.standard.string(forKey: shiftKey),
       let shift = ShiftPeriod(rawValue: rawShift) {
      activeShift = shift
    }

    guard let data = UserDefaults.standard.data(forKey: recordsKey),
          let decoded = try? JSONDecoder().decode([CheckInRecord].self, from: data)
    else { return }

    records = decoded
  }
}
