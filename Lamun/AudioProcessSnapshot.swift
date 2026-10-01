import CoreAudio
import Foundation

enum AudioProcessOutputActivity: Equatable, Sendable {
  case active
  case inactive
  case unavailable

  var label: String {
    switch self {
    case .active:
      "Output I/O active"
    case .inactive:
      "Output I/O inactive"
    case .unavailable:
      "Output state unavailable"
    }
  }
}

struct AudioProcessInstanceID: Hashable, Sendable {
  let audioObjectID: AudioObjectID
  let processIdentifier: pid_t
}

struct AudioProcessSnapshot: Equatable, Identifiable, Sendable {
  let audioObjectID: AudioObjectID
  let processIdentifier: pid_t
  let bundleIdentifier: String?
  let applicationName: String?
  let applicationBundleURL: URL?
  let executableURL: URL?
  let hasApplicationIcon: Bool
  let outputActivity: AudioProcessOutputActivity
  let isConnectedToHAL: Bool
  let lastActiveAt: Date?

  var id: AudioProcessInstanceID {
    AudioProcessInstanceID(
      audioObjectID: audioObjectID,
      processIdentifier: processIdentifier
    )
  }

  /// Bundle IDs identify an app across launches when the process exposes one.
  /// This value is never derived from the transient PID or AudioObjectID.
  var applicationIdentity: String? {
    bundleIdentifier
  }

  var displayName: String {
    if let applicationName, !applicationName.isEmpty {
      return applicationName
    }
    if let bundleIdentifier, !bundleIdentifier.isEmpty {
      return bundleIdentifier
    }
    guard processIdentifier > 0 else { return "Unknown process" }
    return "Process \(processIdentifier)"
  }

  func isRecentlyActive(at date: Date, gracePeriod: TimeInterval = 5) -> Bool {
    guard outputActivity != .active,
      let lastActiveAt,
      gracePeriod >= 0
    else {
      return false
    }

    let elapsed = date.timeIntervalSince(lastActiveAt)
    return elapsed >= 0 && elapsed <= gracePeriod
  }

  func isVisible(at date: Date, gracePeriod: TimeInterval = 5) -> Bool {
    isConnectedToHAL || isRecentlyActive(at: date, gracePeriod: gracePeriod)
  }

  func stateLabel(at date: Date, gracePeriod: TimeInterval = 5) -> String {
    if outputActivity == .active {
      return outputActivity.label
    }
    if isRecentlyActive(at: date, gracePeriod: gracePeriod) {
      return "Recently active"
    }
    return outputActivity.label
  }
}
