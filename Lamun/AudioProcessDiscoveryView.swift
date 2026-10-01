#if DEBUG
  import AppKit
  import CoreAudio
  import SwiftUI

  @available(macOS 15.0, *)
  struct AudioProcessDiscoveryView: View {
    @StateObject private var discovery = AudioProcessDiscovery()
    @StateObject private var gainPoC = AudioGainProofOfConcept()
    @State private var metricsRefreshTick = 0

    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: 8) {
          Text("Refresh \(metricsRefreshTick)").hidden().frame(height: 0)
          Text("Audio Process Discovery · Debug")
            .font(.headline)

          Button("Stop all sessions and quit Lamun") {
            gainPoC.stopAll()
            NSApplication.shared.terminate(nil)
          }

          Text(
            "DEBUG feasibility only: selecting Start temporarily captures this app's audio, applies gain, and re-renders it locally. No audio is saved or uploaded."
          )
          .font(.caption)
          .foregroundStyle(.secondary)

          Picker("Original output", selection: $gainPoC.selectedMuteBehaviorRawValue) {
            Text("Mute while tap is read").tag(CATapMuteBehavior.mutedWhenTapped.rawValue)
            Text("Always mute while tap exists").tag(CATapMuteBehavior.muted.rawValue)
          }
          .pickerStyle(.segmented)

          Text(
            "For a controlled process only. Stop restores native output. The unmuted tap mode is excluded because it would intentionally duplicate output."
          )
          .font(.caption2)
          .foregroundStyle(.secondary)

          if let error = gainPoC.lastError {
            Text(error)
              .font(.caption)
              .foregroundStyle(.red)
          }

          if let errorMessage = discovery.errorMessage {
            Text(errorMessage)
              .foregroundStyle(.red)
          }

          Text("Property listener events: \(discovery.listenerEventCount)")
            .font(.caption.monospacedDigit())

          Text(
            "Process-list listener: \(discovery.isProcessListListenerRegistered ? "registered" : "unavailable")"
          )
          .font(.caption)

          ForEach(discovery.listenerWarnings, id: \.self) { warning in
            Text(warning)
              .font(.caption)
              .foregroundStyle(.red)
          }

          Divider()

          let visible = discovery.snapshots.filter {
            $0.outputActivity == .active
          }
          if visible.isEmpty {
            Text("No Core Audio process objects are currently visible.")
              .foregroundStyle(.secondary)
          } else {
            ForEach(visible) { process in
              VStack(alignment: .leading, spacing: 2) {
                Text(process.displayName)
                  .font(.body.weight(.medium))
                Text("PID \(process.processIdentifier) · object \(process.audioObjectID)")
                  .font(.caption.monospacedDigit())
                  .foregroundStyle(.secondary)
                if let bundleIdentifier = process.bundleIdentifier {
                  Text(bundleIdentifier)
                    .font(.caption.monospaced())
                }
                Text(process.outputActivity.label)
                  .font(.caption)

                HStack {
                  Button(
                    gainPoC.isActive(processObjectID: process.audioObjectID)
                      ? "Stop gain POC" : "Start gain POC"
                  ) {
                    if gainPoC.isActive(processObjectID: process.audioObjectID) {
                      gainPoC.stop(processObjectID: process.audioObjectID)
                    } else {
                      gainPoC.start(process)
                    }
                  }

                  if gainPoC.isActive(processObjectID: process.audioObjectID) {
                    Slider(
                      value: Binding(
                        get: { gainPoC.gain(for: process.audioObjectID) },
                        set: { gainPoC.setGain($0, for: process.audioObjectID) }
                      ),
                      in: 0...1,
                      step: 0.05
                    )
                    Text("\(Int(gainPoC.gain(for: process.audioObjectID) * 100))%")
                      .font(.caption.monospacedDigit())
                      .frame(width: 34, alignment: .trailing)
                  }
                }

                if let metrics = gainPoC.metrics(for: process.audioObjectID) {
                  Text(
                    "HAL callbacks \(metrics.callbackCount) · in \(metrics.inputBufferCount)×\(metrics.inputChannels)ch/\(metrics.inputBufferBytes)B · out \(metrics.outputBufferCount)×\(metrics.outputChannels)ch/\(metrics.outputBufferBytes)B"
                  )
                  .font(.caption2.monospacedDigit())
                  Text(
                    "RMS \(metrics.inputRMS, specifier: "%.4f") → \(metrics.postGainRMS, specifier: "%.4f")"
                  )
                  .font(.caption.monospacedDigit())
                  Text(
                    "Graph callback delta p50/p95/max: \(metrics.callbackLatencyP50Milliseconds.map { String(format: "%.2f", $0) } ?? "—") / \(metrics.callbackLatencyP95Milliseconds.map { String(format: "%.2f", $0) } ?? "—") / \(metrics.callbackLatencyMaximumMilliseconds.map { String(format: "%.2f", $0) } ?? "—") ms"
                  )
                  .font(.caption2.monospacedDigit())
                }

                if gainPoC.isActive(processObjectID: process.audioObjectID) {
                  let info = gainPoC.activeSessions[process.audioObjectID]
                  Text(
                    "\(info?.streamFormatDescription ?? "") · output \(info?.outputDeviceName ?? "") · \(info?.muteBehaviorName ?? "")"
                  )
                  .font(.caption2)
                  .foregroundStyle(.secondary)
                }
              }
              .padding(.vertical, 3)
            }
          }
        }
        .padding(12)
      }
      .frame(minWidth: 420, minHeight: 480, alignment: .topLeading)
      .onAppear { discovery.start() }
      .onReceive(discovery.$snapshots) { snapshots in
        gainPoC.reconcile(with: snapshots)
      }
      .task {
        while !Task.isCancelled {
          try? await Task.sleep(for: .milliseconds(500))
          metricsRefreshTick &+= 1
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .lamunStopExperimentalAudio)) { _ in
        gainPoC.stopAll()
      }
      .onDisappear {
        gainPoC.stopAll()
        discovery.stop()
      }
    }
  }

  extension Notification.Name {
    static let lamunStopExperimentalAudio = Notification.Name("lamun.stopExperimentalAudio")
  }
#endif
