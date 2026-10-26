import XCTest
@testable import K3BatteryCore

final class K3ReportParserTests: XCTestCase {
    func testParsesIOHIDReportWithReportID() throws {
        let reading = try XCTUnwrap(
            K3ReportParser.parse([
                0x03, 0x32,
                0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF
            ])
        )

        XCTAssertEqual(reading.percent, 50)
        XCTAssertEqual(reading.address, "aa:bb:cc:dd:ee:ff")
    }

    func testParsesCallbackReportWithoutReportID() throws {
        let reading = try XCTUnwrap(
            K3ReportParser.parse([
                0x4B,
                0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF
            ])
        )

        XCTAssertEqual(reading.percent, 75)
        XCTAssertEqual(reading.address, "aa:bb:cc:dd:ee:ff")
    }

    func testAcceptsBatteryOnlyReport() throws {
        let reading = try XCTUnwrap(K3ReportParser.parse([0x03, 0x14]))

        XCTAssertEqual(reading.percent, 20)
        XCTAssertNil(reading.address)
    }

    func testRejectsOutOfRangePercentage() {
        XCTAssertNil(K3ReportParser.parse([0x03, 0x65]))
        XCTAssertNil(K3ReportParser.parse([0x65]))
    }

    func testRejectsUnexpectedReportID() {
        XCTAssertNil(K3ReportParser.parse([0x04, 0x32]))
    }
}
