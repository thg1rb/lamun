import AppKit
import SwiftUI

@main
struct LamunApp: App {
  var body: some Scene {
    MenuBarExtra("Lamun", systemImage: "speaker.wave.2") {
      #if DEBUG
        if #available(macOS 15.0, *) {
          AudioProcessDiscoveryView()
        } else {
          Text("Audio process discovery requires macOS 15 or later in this prototype.")
        }
      #else
        Text("Audio controls are being prepared.")
      #endif

      Divider()

      Button("Quit Lamun") {
        NSApplication.shared.terminate(nil)
      }
    }
  }
}
