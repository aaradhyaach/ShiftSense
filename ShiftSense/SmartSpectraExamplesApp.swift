//
//  ShiftSenseApp.swift
//  ShiftSense
//

import AVFoundation
import SmartSpectraSwiftSDK
import SwiftUI

@main
struct ShiftSenseApp: App {
  @StateObject private var store = CheckInStore()

  init() {
    SmartSpectraBootstrap.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(store)
    }
  }
}

enum SmartSpectraBootstrap {
  static func configure() {
    let sdk = SmartSpectraSwiftSDK.shared

    if let url = Bundle.main.url(forResource: "PresageService-Info", withExtension: "plist"),
       let dict = NSDictionary(contentsOf: url) as? [String: Any],
       let apiKey = dict["API_KEY"] as? String,
       !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      sdk.setApiKey(apiKey)
      print("Loaded API key from PresageService-Info.plist")
    } else {
      print("ERROR: Could not load API key from PresageService-Info.plist")
      print("Bundle path for plist:", Bundle.main.path(forResource: "PresageService-Info", ofType: "plist") ?? "nil")
    }

    sdk.setSmartSpectraMode(.continuous)
    sdk.setCameraPosition(.front)
    sdk.setMeasurementDuration(15)
    sdk.setImageOutputEnabled(true)
    sdk.showControlsInScreeningView(false)
  }
}
