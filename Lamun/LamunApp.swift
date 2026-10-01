import AppKit
import SwiftUI

@main
struct LamunApp: App {
  #if DEBUG || W003_VALIDATION
    @NSApplicationDelegateAdaptor(W003DiagnosticAppDelegate.self) private var diagnosticDelegate
  #endif

  var body: some Scene {
    MenuBarExtra("Lamun", systemImage: "speaker.wave.2") {
      #if DEBUG || W003_VALIDATION
        if #available(macOS 15.0, *) {
          Button("Open W003 Audio Diagnostic") {
            diagnosticDelegate.showWindow()
          }
        } else {
          Text("Audio process discovery requires macOS 15 or later in this prototype.")
        }
      #else
        Text("Audio controls are being prepared.")
      #endif

      Divider()

      Button("Quit Lamun") {
        #if DEBUG || W003_VALIDATION
          NotificationCenter.default.post(name: .lamunStopExperimentalAudio, object: nil)
        #endif
        NSApplication.shared.terminate(nil)
      }
    }

  }
}

#if DEBUG || W003_VALIDATION
  @MainActor
  final class W003DiagnosticAppDelegate: NSObject, NSApplicationDelegate {
    private var diagnosticWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
      showWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
      NotificationCenter.default.post(name: .lamunStopExperimentalAudio, object: nil)
    }

    func showWindow() {
      guard #available(macOS 15.0, *) else { return }
      if diagnosticWindow == nil {
        let window = NSWindow(
          contentRect: NSRect(x: 0, y: 0, width: 520, height: 720),
          styleMask: [.titled, .closable, .miniaturizable, .resizable],
          backing: .buffered,
          defer: false
        )
        window.title = "W003 Audio Diagnostic"
        window.contentView = NSHostingView(rootView: AudioProcessDiscoveryView())
        window.center()
        diagnosticWindow = window
      }
      diagnosticWindow?.makeKeyAndOrderFront(nil)
      NSApplication.shared.activate(ignoringOtherApps: true)
    }
  }
#endif
