import AppKit
import Combine
import CoreAudio
import Foundation

@available(macOS 15.0, *)
@MainActor
final class AudioProcessDiscovery: ObservableObject {
  @Published private(set) var snapshots: [AudioProcessSnapshot] = []
  @Published private(set) var errorMessage: String?
  @Published private(set) var listenerWarnings: [String] = []
  @Published private(set) var listenerEventCount = 0
  @Published private(set) var isProcessListListenerRegistered = false

  private let system = AudioHardwareSystem.shared
  private let callbackQueue = DispatchQueue(label: "org.example.lamun.process-discovery")
  private let addProcessListListener:
    (
      AudioHardwareSystem,
      [AudioObjectPropertyAddress],
      DispatchQueue
    ) throws -> Void
  private var systemRegistration: ListenerRegistration?
  private var processRegistrations: [AudioObjectID: ListenerRegistration] = [:]
  private var recordsByID: [AudioObjectID: AudioProcessSnapshot] = [:]
  private var hasStarted = false

  init(
    addProcessListListener:
      @escaping (
        AudioHardwareSystem,
        [AudioObjectPropertyAddress],
        DispatchQueue
      ) throws -> Void = { system, properties, queue in
        try system.addListener(forProperties: properties, dispatchQueue: queue)
      }
  ) {
    self.addProcessListListener = addProcessListListener
  }

  func start() {
    guard !hasStarted else { return }
    hasStarted = true

    let observer = makeObserver()
    add(observer, to: system)
    let properties = [PropertyAddress(kAudioHardwarePropertyProcessObjectList)]
    do {
      try addProcessListListener(system, properties, callbackQueue)
      systemRegistration = ListenerRegistration(
        object: system,
        observer: observer,
        properties: properties
      )
      isProcessListListenerRegistered = true
    } catch {
      remove(observer, from: system)
      addListenerWarning("Process-list listener failed: \(error.localizedDescription)")
    }

    refresh()
  }

  func stop() {
    guard hasStarted else { return }
    hasStarted = false

    if let systemRegistration {
      remove(systemRegistration)
      self.systemRegistration = nil
    }
    isProcessListListenerRegistered = false

    for registration in processRegistrations.values {
      remove(registration)
    }
    processRegistrations.removeAll()
    recordsByID.removeAll()
    snapshots = []
  }

  private func makeObserver() -> CoreAudioPropertyObserver {
    CoreAudioPropertyObserver { [weak self] in
      Task { @MainActor [weak self] in
        self?.listenerDidChange()
      }
    }
  }

  private func listenerDidChange() {
    guard hasStarted else { return }
    listenerEventCount += 1
    refresh()
  }

  private func refresh() {
    guard hasStarted else { return }

    let processes: [AudioHardwareProcess]
    do {
      processes = try system.processes
    } catch {
      errorMessage = "Process enumeration failed: \(error.localizedDescription)"
      return
    }

    errorMessage = nil
    let processesByID = Dictionary(
      processes.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
    let presentIDs = Set(processesByID.keys)

    for process in processesByID.values {
      registerProcessListenerIfNeeded(for: process)
      let previous = recordsByID[process.id]
      recordsByID[process.id] = makeSnapshot(for: process, previous: previous)
    }

    // Reconcile snapshots as well as registered listeners. A listener can fail
    // to register, but its process row still must not survive termination.
    let removedIDs = recordsByID.keys.filter { !presentIDs.contains($0) }
    for objectID in removedIDs {
      if let registration = processRegistrations.removeValue(forKey: objectID) {
        remove(registration)
      }
      markDisconnected(objectID)
    }

    snapshots = recordsByID.values.sorted {
      if $0.isConnectedToHAL != $1.isConnectedToHAL {
        return $0.isConnectedToHAL
      }
      return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
    }
  }

  private func makeSnapshot(
    for process: AudioHardwareProcess,
    previous: AudioProcessSnapshot?
  ) -> AudioProcessSnapshot {
    let processIdentifier = (try? process.pid) ?? -1
    let bundleIdentifier = try? process.bundleID
    let runningOutput = try? process.isRunningOutput
    let application =
      processIdentifier > 0
      ? NSRunningApplication(processIdentifier: processIdentifier)
      : nil
    let outputActivity: AudioProcessOutputActivity
    if let runningOutput {
      outputActivity = runningOutput ? .active : .inactive
    } else {
      outputActivity = .unavailable
    }

    let lastActiveAt: Date?
    if outputActivity == .active {
      lastActiveAt = Date()
    } else {
      lastActiveAt = previous?.lastActiveAt
    }

    return AudioProcessSnapshot(
      audioObjectID: process.id,
      processIdentifier: processIdentifier,
      bundleIdentifier: bundleIdentifier ?? application?.bundleIdentifier,
      applicationName: application?.localizedName,
      applicationBundleURL: application?.bundleURL,
      executableURL: application?.executableURL,
      hasApplicationIcon: application?.icon != nil,
      outputActivity: outputActivity,
      isConnectedToHAL: true,
      lastActiveAt: lastActiveAt
    )
  }

  private func registerProcessListenerIfNeeded(for process: AudioHardwareProcess) {
    guard processRegistrations[process.id] == nil else { return }

    let observer = makeObserver()
    add(observer, to: process)
    let properties = [PropertyAddress(kAudioProcessPropertyIsRunningOutput)]
    do {
      try process.addListener(forProperties: properties, dispatchQueue: callbackQueue)
      processRegistrations[process.id] = ListenerRegistration(
        object: process,
        observer: observer,
        properties: properties
      )
    } catch {
      remove(observer, from: process)
      addListenerWarning(
        "Output-state listener failed for process object \(process.id): \(error.localizedDescription)"
      )
    }
  }

  private func markDisconnected(_ objectID: AudioObjectID) {
    guard let previous = recordsByID[objectID] else { return }
    let disconnected = AudioProcessSnapshot(
      audioObjectID: previous.audioObjectID,
      processIdentifier: previous.processIdentifier,
      bundleIdentifier: previous.bundleIdentifier,
      applicationName: previous.applicationName,
      applicationBundleURL: previous.applicationBundleURL,
      executableURL: previous.executableURL,
      hasApplicationIcon: previous.hasApplicationIcon,
      outputActivity: .inactive,
      isConnectedToHAL: false,
      lastActiveAt: previous.lastActiveAt
    )

    if disconnected.isRecentlyActive(at: Date()) {
      recordsByID[objectID] = disconnected
      let expectedLastActiveAt = disconnected.lastActiveAt
      DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
        guard let self,
          self.hasStarted,
          self.recordsByID[objectID]?.lastActiveAt == expectedLastActiveAt
        else {
          return
        }
        self.recordsByID.removeValue(forKey: objectID)
        self.snapshots = Array(self.recordsByID.values)
      }
    } else {
      recordsByID.removeValue(forKey: objectID)
    }
  }

  private func remove(_ registration: ListenerRegistration) {
    do {
      try registration.object.removeListener(
        forProperties: registration.properties,
        dispatchQueue: callbackQueue
      )
    } catch {
      addListenerWarning("Property-listener cleanup failed: \(error.localizedDescription)")
    }
    remove(registration.observer, from: registration.object)
  }

  private func add(_ observer: CoreAudioPropertyObserver, to object: AudioHardwareObject) {
    object.delegates.append(observer)
  }

  private func remove(_ observer: CoreAudioPropertyObserver, from object: AudioHardwareObject) {
    let observerIdentifier = ObjectIdentifier(observer)
    object.delegates.removeAll { ObjectIdentifier($0 as AnyObject) == observerIdentifier }
  }

  private func addListenerWarning(_ message: String) {
    guard !listenerWarnings.contains(message) else { return }
    listenerWarnings.append(message)
  }
}

@available(macOS 15.0, *)
private struct ListenerRegistration {
  let object: AudioHardwareObject
  let observer: CoreAudioPropertyObserver
  let properties: [AudioObjectPropertyAddress]
}

@available(macOS 15.0, *)
private final class CoreAudioPropertyObserver: PropertyListenerDelegate, @unchecked Sendable {
  private let onChange: @Sendable () -> Void

  init(onChange: @escaping @Sendable () -> Void) {
    self.onChange = onChange
  }

  func propertiesChanged(properties: [AudioObjectPropertyAddress]) {
    onChange()
  }
}
