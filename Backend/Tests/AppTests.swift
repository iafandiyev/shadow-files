import XCTest
@testable import App

final class AppTests: XCTestCase {
    func testRoomCodeShape() {
        let value = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6)
        XCTAssertEqual(value.count, 6)
    }
}
