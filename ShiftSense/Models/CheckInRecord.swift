import Foundation

enum ShiftPeriod: String, Codable, CaseIterable, Identifiable {
  case day
  case evening
  case night

  var id: String { rawValue }

  var title: String {
    switch self {
    case .day: return "Day Shift"
    case .evening: return "Evening Shift"
    case .night: return "Night Shift"
    }
  }
}

struct CheckInRecord: Identifiable, Codable {
  let id: UUID
  let timestamp: Date
  let pulse: Int
  let breathing: Int
  let level: WellnessLevel
  let shiftId: String
  let shiftName: String
  let aiInsight: String

  init(
    pulse: Int,
    breathing: Int,
    level: WellnessLevel,
    shiftId: String,
    shiftName: String,
    aiInsight: String
  ) {
    self.id = UUID()
    self.timestamp = Date()
    self.pulse = pulse
    self.breathing = breathing
    self.level = level
    self.shiftId = shiftId
    self.shiftName = shiftName
    self.aiInsight = aiInsight
  }
}
