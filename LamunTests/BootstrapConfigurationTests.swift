import Foundation
import Testing

@Suite("Bootstrap app configuration")
struct BootstrapConfigurationTests {
  @Test("Lamun runs as a Menu Bar utility")
  func menuBarUtility() {
    #expect(Bundle.main.object(forInfoDictionaryKey: "LSUIElement") as? Bool == true)
  }
}
