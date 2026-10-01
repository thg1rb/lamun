import CoreAudio
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
    #expect(discovery.isProcessListListenerRegistered)
    let allSnapshotsAreConnected = discovery.snapshots.allSatisfy { $0.isConnectedToHAL }
    #expect(allSnapshotsAreConnected)

    discovery.stop()
    #expect(discovery.snapshots.isEmpty)
    #expect(!discovery.isProcessListListenerRegistered)
  }

  @Test("Preserves delegates owned by other Core Audio clients")
  @MainActor
  func preservesOtherSystemDelegates() {
    guard #available(macOS 15.0, *) else { return }

    let system = AudioHardwareSystem.shared
    let previousDelegates = system.delegates
    let otherObserver = DiscoveryTestObserver()
    let otherObserverIdentifier = ObjectIdentifier(otherObserver)
    system.delegates = previousDelegates + [otherObserver]
    defer { system.delegates = previousDelegates }

    let discovery = AudioProcessDiscovery()
    discovery.start()
    let retainedWhileRunning = system.delegates.contains {
      ObjectIdentifier($0 as AnyObject) == otherObserverIdentifier
    }
    #expect(retainedWhileRunning)

    discovery.stop()
    let retainedAfterStop = system.delegates.contains {
      ObjectIdentifier($0 as AnyObject) == otherObserverIdentifier
    }
    #expect(retainedAfterStop)
  }

  @Test("Surfaces process-list listener failure and removes its observer")
  @MainActor
  func surfacesListenerFailureAndRemovesObserver() {
    guard #available(macOS 15.0, *) else { return }

    let system = AudioHardwareSystem.shared
    let previousDelegates = system.delegates
    let otherObserver = DiscoveryTestObserver()
    let expectedDelegateIdentifiers = (previousDelegates + [otherObserver]).map {
      ObjectIdentifier($0 as AnyObject)
    }
    system.delegates = previousDelegates + [otherObserver]
    defer { system.delegates = previousDelegates }

    let discovery = AudioProcessDiscovery(addProcessListListener: { _, _, _ in
      throw DiscoveryTestError.forcedListenerFailure
    })
    discovery.start()

    #expect(!discovery.isProcessListListenerRegistered)
    #expect(discovery.errorMessage == nil)
    let surfacedFailure = discovery.listenerWarnings.contains {
      $0.hasPrefix("Process-list listener failed:")
    }
    #expect(surfacedFailure)
    let currentDelegateIdentifiers = system.delegates.map {
      ObjectIdentifier($0 as AnyObject)
    }
    #expect(currentDelegateIdentifiers == expectedDelegateIdentifiers)

    discovery.stop()
  }
}

@available(macOS 15.0, *)
private final class DiscoveryTestObserver: PropertyListenerDelegate, @unchecked Sendable {
  func propertiesChanged(properties: [AudioObjectPropertyAddress]) {}
}

private enum DiscoveryTestError: Error {
  case forcedListenerFailure
}
