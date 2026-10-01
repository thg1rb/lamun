import CoreAudio
import Foundation
import Testing

@testable import Lamun

@Suite("Audio process snapshot")
struct AudioProcessSnapshotTests {
  @Test(
    "POC gain is bounded to attenuation and unity",
    arguments: [
      (input: -0.5, expected: 0.0),
      (input: 0.0, expected: 0.0),
      (input: 0.25, expected: 0.25),
      (input: 0.5, expected: 0.5),
      (input: 0.75, expected: 0.75),
      (input: 1.0, expected: 1.0),
      (input: 1.5, expected: 1.0),
    ]
  )
  func gainNormalizationIsBounded(input: Double, expected: Double) {
    #expect(AudioGainValue.normalized(input) == expected)
  }

  @Test("Non-finite POC gain fails safe to unity")
  func nonFiniteGainReturnsUnity() {
    #expect(AudioGainValue.normalized(.nan) == 1)
    #expect(AudioGainValue.normalized(.infinity) == 1)
  }

  @Test("Application identity uses bundle ID rather than process identifiers")
  func identityUsesBundleIdentifier() {
    let snapshot = makeSnapshot(bundleIdentifier: "com.example.player")

    #expect(snapshot.applicationIdentity == "com.example.player")
    #expect(snapshot.id.processIdentifier == 123)
    #expect(snapshot.id.audioObjectID == 456)
  }

  @Test("Missing bundle ID does not invent a persistent application identity")
  func missingBundleIdentifierHasNoApplicationIdentity() {
    let snapshot = makeSnapshot(bundleIdentifier: nil)

    #expect(snapshot.applicationIdentity == nil)
    #expect(snapshot.displayName == "Process 123")
  }

  @Test("Recent activity remains visible only inside its grace period")
  func recentActivityExpires() {
    let lastActive = Date(timeIntervalSince1970: 1_000)
    let snapshot = makeSnapshot(
      outputActivity: .inactive,
      isConnectedToHAL: false,
      lastActiveAt: lastActive
    )

    #expect(snapshot.isRecentlyActive(at: lastActive.addingTimeInterval(5)))
    #expect(!snapshot.isRecentlyActive(at: lastActive.addingTimeInterval(5.01)))
    #expect(!snapshot.isRecentlyActive(at: lastActive.addingTimeInterval(-0.1)))
    #expect(!snapshot.isVisible(at: lastActive.addingTimeInterval(5.01)))
  }

  @Test("Output-active state is not labeled as recently active")
  func activeStateHasPriority() {
    let date = Date(timeIntervalSince1970: 1_000)
    let snapshot = makeSnapshot(outputActivity: .active, lastActiveAt: date)

    #expect(!snapshot.isRecentlyActive(at: date))
    #expect(snapshot.stateLabel(at: date) == "Output I/O active")
  }

  private func makeSnapshot(
    bundleIdentifier: String? = "com.example.player",
    outputActivity: AudioProcessOutputActivity = .active,
    isConnectedToHAL: Bool = true,
    lastActiveAt: Date? = Date(timeIntervalSince1970: 1_000)
  ) -> AudioProcessSnapshot {
    AudioProcessSnapshot(
      audioObjectID: AudioObjectID(456),
      processIdentifier: 123,
      bundleIdentifier: bundleIdentifier,
      applicationName: nil,
      applicationBundleURL: nil,
      executableURL: nil,
      hasApplicationIcon: false,
      outputActivity: outputActivity,
      isConnectedToHAL: isConnectedToHAL,
      lastActiveAt: lastActiveAt
    )
  }
}
