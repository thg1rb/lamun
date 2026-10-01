import AppKit
import SwiftUI

@main
struct LamunApp: App {
  var body: some Scene {
    MenuBarExtra("Lamun", systemImage: "speaker.wave.2") {
      #if DEBUG
        if #available(macOS 15.0, *) {
          OpenAudioDiagnosticButton()
        } else {
          Text("Audio process discovery requires macOS 15 or later in this prototype.")
        }
      #else
        Text("Audio controls are being prepared.")
      #endif

      Divider()

      Button("Quit Lamun") {
        #if DEBUG
          NotificationCenter.default.post(name: .lamunStopExperimentalAudio, object: nil)
        #endif
        NSApplication.shared.terminate(nil)
      }
    }

    #if DEBUG
      Window("W003 Audio Diagnostic", id: "w003-audio-diagnostic") {
        if #available(macOS 15.0, *) {
          AudioProcessDiscoveryView()
        } else {
          Text("Audio process discovery requires macOS 15 or later in this prototype.")
        }
      }
      .defaultSize(width: 520, height: 720)
    #endif
  }
}

#if DEBUG
  private struct OpenAudioDiagnosticButton: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
      Button("Open W003 Audio Diagnostic") {
        openWindow(id: "w003-audio-diagnostic")
      }
    }
  }
#endif
