import XCTest

final class LamunLaunchTests: XCTestCase {
  @MainActor
  func testApplicationLaunches() {
    let app = XCUIApplication()
    app.launch()
    XCTAssertNotEqual(app.state, .notRunning)
    app.terminate()
  }
}
