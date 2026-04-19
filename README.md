# ShiftSense

**Contactless clinician wellness check-ins powered by Presage vitals sensing and Gemini AI.**

ShiftSense is an iOS app that uses your device's front camera to run 15-second physiologic check-ins during a clinical shift. It translates raw pulse and breathing data into plain-language insights, tracks wellness trends across a shift, and surfaces recovery actions before strain compounds.

## What it does

- **15-second contactless scan** — uses the Presage SmartSpectra SDK to measure pulse rate and breathing rate via front camera, no wearables required
- **Gemini AI interpretation** — each check-in generates a personalized clinical-style insight via the Gemini 1.5 Flash API, contextualized to shift type and prior strain history
- **Shift-aware trend tracking** — check-ins are grouped by shift (Day / Evening / Night) and stored persistently, surfacing cumulative strain patterns not visible from a single reading
- **Adaptive recovery plan** — recovery guidance adjusts based on wellness level (Calm / Elevated / Strained) and escalates if strain repeats across the shift
- **Sustainability focus** — uses existing device hardware instead of dedicated wearables, reducing cost, e-waste, and procurement burden for healthcare systems

## Prize tracks

- [MLH] Best Use of Presage
- [MLH] Best Use of Gemini API
- [Main Track] Sustainability

## Tech stack

- Swift / SwiftUI (iOS 17+)
- Presage SmartSpectra Swift SDK
- Google Gemini 1.5 Flash API
- Swift Charts
- Combine

## Requirements

- Xcode 16+
- iOS 17+ physical device (camera required, simulator not supported)
- Presage developer account — [physiology.presagetech.com](https://physiology.presagetech.com)
- Google Gemini API key — [aistudio.google.com](https://aistudio.google.com)

## Setup

1. Clone the repo
2. Copy `ShiftSense/Secrets.example.swift` to `ShiftSense/Secrets.swift` and add your API keys
3. Copy `ShiftSense/PresageService-Info.example.plist` to `ShiftSense/PresageService-Info.plist` and add your Presage credentials
4. Open `ShiftSense.xcodeproj` in Xcode
5. Set your signing team under Signing & Capabilities
6. Build and run on a physical iOS device

## Disclaimer

For wellness and self-awareness only. Not intended for clinical diagnosis or treatment.
