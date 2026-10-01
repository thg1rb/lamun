import Foundation
import Testing

@testable import Lamun

@Suite("Audio process discovery integration")
struct AudioProcessDiscoveryIntegrationTests {
  @Test("Starts and stops Core Audio discovery without an API error")
  @MainActor
  func enumeratesClientsAndStops() async throws {
    guard #available(macOS 15.0, *) else { return }

    let discovery = AudioProcessDiscovery()
    discovery.start()

    #expect(discovery.errorMessage == nil)
    let allSnapshotsAreConnected = discovery.snapshots.allSatisfy { $0.isConnectedToHAL }
    #expect(allSnapshotsAreConnected)

    discovery.stop()
    #expect(discovery.snapshots.isEmpty)
  }
}
