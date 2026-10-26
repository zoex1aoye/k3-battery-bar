import Foundation

public struct K3BatteryReading: Equatable, Sendable {
    public let percent: Int
    public let address: String?
    public let rawReport: [UInt8]
    public let timestamp: Date

    public init(
        percent: Int,
        address: String?,
        rawReport: [UInt8],
        timestamp: Date = Date()
    ) {
        self.percent = percent
        self.address = address
        self.rawReport = rawReport
        self.timestamp = timestamp
    }
}

public enum K3ReportParser {
    public static let reportID: UInt8 = 3

    /// `IOHIDDeviceGetReport` includes the report ID in the returned buffer.
    /// Some HID callbacks omit it, so both layouts are accepted.
    public static func parse(_ bytes: [UInt8]) -> K3BatteryReading? {
        let percentIndex: Int
        let addressStart: Int

        if bytes.count >= 2,
           bytes[0] == reportID,
           bytes[1] <= 100 {
            percentIndex = 1
            addressStart = 2
        } else if bytes.count >= 7, bytes[0] <= 100 {
            // Without a report ID, require the six-byte Bluetooth address so
            // another short report cannot be mistaken for the battery value.
            percentIndex = 0
            addressStart = 1
        } else {
            return nil
        }

        let address: String?
        if bytes.count >= addressStart + 6 {
            address = bytes[addressStart..<(addressStart + 6)]
                .map { String(format: "%02x", $0) }
                .joined(separator: ":")
        } else {
            address = nil
        }

        return K3BatteryReading(
            percent: Int(bytes[percentIndex]),
            address: address,
            rawReport: bytes
        )
    }
}
