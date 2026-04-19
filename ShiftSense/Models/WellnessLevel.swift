import Foundation
import SwiftUI

enum WellnessLevel: String, Codable, CaseIterable, Identifiable {
  case awaiting
  case calm
  case elevated
  case strained

  var id: String { rawValue }

  static func from(pulse: Int, breathing: Int) -> WellnessLevel {
    let hasResults = pulse > 0 || breathing > 0
    guard hasResults else { return .awaiting }

    if pulse >= 95 || breathing >= 22 {
      return .strained
    } else if pulse >= 80 || breathing >= 18 {
      return .elevated
    } else {
      return .calm
    }
  }

  var title: String {
    switch self {
    case .awaiting: return "Awaiting scan"
    case .calm: return "Calm"
    case .elevated: return "Elevated"
    case .strained: return "Strained"
    }
  }

  var color: Color {
    switch self {
    case .awaiting: return .gray
    case .calm: return .green
    case .elevated: return .orange
    case .strained: return .red
    }
  }

  func subtitle(hasResults: Bool) -> String {
    guard hasResults else {
      return "Run a 15-second scan to view your pulse and breathing summary."
    }

    switch self {
    case .awaiting:
      return "Run a 15-second scan to view your pulse and breathing summary."
    case .calm:
      return "Current signals appear steady."
    case .elevated:
      return "Current signals are mildly elevated."
    case .strained:
      return "Current signals suggest increased strain."
    }
  }

  func recommendation() -> String {
    switch self {
    case .awaiting:
      return "No recommendation yet."
    case .calm:
      return "Continue working and re-check after your next demanding task."
    case .elevated:
      return "Pause briefly, hydrate, and take a short visual break before resuming."
    case .strained:
      return "Start the recovery plan now, step away briefly if possible, and re-check after the reset."
    }
  }

  var recoveryHeadline: String {
    switch self {
    case .awaiting: return "General recovery plan"
    case .calm: return "Maintenance recovery plan"
    case .elevated: return "Early recovery plan"
    case .strained: return "Active recovery plan"
    }
  }

  var recoveryIntro: String {
    switch self {
    case .awaiting:
      return "Use this plan whenever you want a quick reset."
    case .calm:
      return "Your latest check-in looked steady. Use this lighter plan to maintain recovery across the shift."
    case .elevated:
      return "Your latest check-in was elevated. Use this short reset to reduce early strain before it builds."
    case .strained:
      return "Your latest check-in suggests higher strain. Use this recovery sequence before continuing demanding work."
    }
  }

  func defaultInsight(
    pulse: Int,
    breathing: Int,
    strainedCountThisShift: Int,
    shiftName: String
  ) -> String {
    switch self {
    case .awaiting:
      return "Run a check-in to generate an interpretation."
    case .calm:
      return "Pulse \(pulse) bpm and breathing \(breathing)/min fall in a relatively steady range for this \(shiftName.lowercased()) shift check-in, suggesting current physiological load is manageable."
    case .elevated:
      if strainedCountThisShift >= 2 {
        return "Pulse \(pulse) bpm and breathing \(breathing)/min are elevated, and repeated elevated check-ins in this \(shiftName.lowercased()) shift may indicate accumulating workload strain rather than a single transient spike."
      }
      return "Pulse \(pulse) bpm and breathing \(breathing)/min are mildly elevated, which can reflect cognitive load, recent activity, or early stress accumulation during the current shift."
    case .strained:
      return "Pulse \(pulse) bpm and breathing \(breathing)/min fall in the strained range, which may reflect sustained physiologic strain during the current shift."
    }
  }
}
