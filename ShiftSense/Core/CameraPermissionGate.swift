//
//  CameraPermissionGate.swift
//  ShiftSense
//

import AVFoundation
import SwiftUI
import UIKit

struct CameraPermissionGate: ViewModifier {
  @Environment(\.scenePhase) private var scenePhase
  @State private var showAlert = false
  @State private var lastReportedStatus: CameraPermission.Status?

  func body(content: Content) -> some View {
    content
      .task(id: scenePhase) { await handlePhaseChange() }
      .alert("Camera Access Needed", isPresented: $showAlert) {
        Button("Open Settings") { CameraPermission.openSettings() }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("Camera access is needed to run your ShiftSense wellness check.")
      }
  }

  @MainActor
  private func handlePhaseChange() async {
    guard scenePhase == .active else { return }
    let status = CameraPermission.status()
    if status != lastReportedStatus {
      lastReportedStatus = status
    }

    #if targetEnvironment(simulator)
      showAlert = false
    #else
      switch status {
      case .notDetermined:
        let granted = await CameraPermission.requestAccess()
        showAlert = !granted
      case .denied, .restricted:
        showAlert = true
      case .authorized, .unknown:
        showAlert = false
      }
    #endif
  }
}

extension View {
  func cameraPermissionGate() -> some View { modifier(CameraPermissionGate()) }
}

enum CameraPermission {
  enum Status {
    case authorized
    case denied
    case restricted
    case notDetermined
    case unknown
  }

  static func status() -> Status {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized: return .authorized
    case .denied: return .denied
    case .restricted: return .restricted
    case .notDetermined: return .notDetermined
    @unknown default: return .unknown
    }
  }

  static func requestAccess() async -> Bool {
    if #available(iOS 17, *) {
      return await AVCaptureDevice.requestAccess(for: .video)
    }
    return await withCheckedContinuation { continuation in
      AVCaptureDevice.requestAccess(for: .video) { granted in
        continuation.resume(returning: granted)
      }
    }
  }

  @MainActor
  static func openSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString),
          UIApplication.shared.canOpenURL(url) else { return }
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
  }
}
