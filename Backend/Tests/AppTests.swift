import XCTest
@testable import App

final class AppTests: XCTestCase {
    func testRoomCodeHasSixCharacters() {
        XCTAssertEqual(RoomManager.makeRoomCode().count, 6)
    }

    func testRoomCodeIsUppercaseAndAlphanumeric() {
        let code = RoomManager.makeRoomCode()
        XCTAssertEqual(code, code.uppercased())
        XCTAssertTrue(code.allSatisfy { $0.isLetter || $0.isNumber })
    }
}
