import Foundation

enum GeminiInsightService {
    private static let apiKey = Secrets.geminiAPIKey

  static func generateInsight(
    pulse: Int,
    breathing: Int,
    level: WellnessLevel,
    shiftName: String,
    strainedCountThisShift: Int
  ) async -> String {
    let prompt = buildPrompt(
      pulse: pulse,
      breathing: breathing,
      level: level,
      shiftName: shiftName,
      strainedCountThisShift: strainedCountThisShift
    )

    do {
      let result = try await callGemini(prompt: prompt)
      return result
    } catch {
      print("DEBUG: Gemini error: \(error)")
      return level.defaultInsight(
        pulse: pulse,
        breathing: breathing,
        strainedCountThisShift: strainedCountThisShift,
        shiftName: shiftName
      )
    }
  }

  private static func buildPrompt(
    pulse: Int,
    breathing: Int,
    level: WellnessLevel,
    shiftName: String,
    strainedCountThisShift: Int
  ) -> String {
    var context = ""
    if strainedCountThisShift >= 2 {
      context = "This is the \(strainedCountThisShift.ordinal) strained reading this shift, suggesting a cumulative pattern rather than a single transient spike."
    } else if strainedCountThisShift == 1 {
      context = "There has been one prior strained reading this shift."
    } else {
      context = "No prior strained readings this shift."
    }

    return """
    You are a clinical informatics assistant helping healthcare workers understand their physiologic check-in results. \
    Write a 2-3 sentence plain-language interpretation of the following vitals reading for a clinician during a \(shiftName.lowercased()). \
    Be concise, clinically grounded, and avoid alarming language. Do not use the word "stress". \
    Do not recommend seeking medical attention. Focus on workload awareness and recovery.

    Vitals: Pulse \(pulse) bpm, Breathing \(breathing) breaths/min, Wellness level: \(level.title).
    Shift context: \(context)

    Respond with the interpretation only. No preamble, no labels, no bullet points.
    """
  }

  private static func callGemini(prompt: String) async throws -> String {
      let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-8b:generateContent?key=\(apiKey)"

    print("DEBUG: Calling Gemini with URL: \(urlString.prefix(80))...")

    guard let url = URL(string: urlString) else {
      print("DEBUG: Invalid URL")
      throw GeminiError.invalidURL
    }

    let requestBody: [String: Any] = [
      "contents": [
        [
          "parts": [
            ["text": prompt]
          ]
        ]
      ],
      "generationConfig": [
        "temperature": 0.4,
        "maxOutputTokens": 150
      ]
    ]

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 15
    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

    print("DEBUG: Sending request...")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      print("DEBUG: Not an HTTP response")
      throw GeminiError.badResponse
    }

    print("DEBUG: HTTP status code: \(httpResponse.statusCode)")

    guard httpResponse.statusCode == 200 else {
      let body = String(data: data, encoding: .utf8) ?? "no body"
      print("DEBUG: Non-200 response body: \(body)")
      throw GeminiError.badResponse
    }

    let rawString = String(data: data, encoding: .utf8) ?? "unreadable"
    print("DEBUG: Raw response: \(rawString.prefix(300))")

    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let candidates = json["candidates"] as? [[String: Any]],
          let first = candidates.first,
          let content = first["content"] as? [String: Any],
          let parts = content["parts"] as? [[String: Any]],
          let text = parts.first?["text"] as? String else {
      print("DEBUG: JSON parse failed")
      throw GeminiError.parseError
    }

    print("DEBUG: Gemini success: \(text.prefix(100))")
    return text.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

private enum GeminiError: Error {
  case invalidURL
  case badResponse
  case parseError
}

private extension Int {
  var ordinal: String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(from: NSNumber(value: self)) ?? "\(self)th"
  }
}
