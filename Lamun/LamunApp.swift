import AppKit
import SwiftUI

@main
struct LamunApp: App {
  var body: some Scene {
    MenuBarExtra("Lamun", systemImage: "speaker.wave.2") {
      Text("Audio controls are being prepared.")

      Divider()

      Button("Quit Lamun") {
        NSApplication.shared.terminate(nil)
      }
    }
  }
}
