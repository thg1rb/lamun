import SwiftUI

@available(macOS 15.0, *)
struct AudioProcessDiscoveryView: View {
  @StateObject private var discovery = AudioProcessDiscovery()

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1)) { timeline in
      VStack(alignment: .leading, spacing: 8) {
        Text("Audio Process Discovery · Debug")
          .font(.headline)

        Text("Output I/O activity only. Lamun does not capture audio samples.")
          .font(.caption)
          .foregroundStyle(.secondary)

        if let errorMessage = discovery.errorMessage {
          Text(errorMessage)
            .foregroundStyle(.red)
        }

        Text("Property listener events: \(discovery.listenerEventCount)")
          .font(.caption.monospacedDigit())

        Divider()

        let visible = discovery.snapshots.filter { $0.isVisible(at: timeline.date) }
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
              Text(process.stateLabel(at: timeline.date))
                .font(.caption)
            }
            .padding(.vertical, 3)
          }
        }
      }
      .padding(12)
      .frame(minWidth: 320, alignment: .leading)
    }
    .onAppear { discovery.start() }
    .onDisappear { discovery.stop() }
  }
}
