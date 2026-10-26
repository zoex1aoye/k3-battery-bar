import Foundation
import IOKit.hid

public enum K3HIDAccess: String, Sendable {
    case granted
    case denied
    case unknown
}

public enum K3HIDError: LocalizedError {
    case accessDenied
    case notFound
    case cannotOpen(IOReturn)
    case cannotRead(IOReturn)
    case invalidReport([UInt8])

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "未获得输入监控权限"
        case .notFound:
            return "未找到通过蓝牙连接的 Keychron K3"
        case .cannotOpen(let code):
            return String(format: "无法打开键盘 HID 设备 (0x%08x)", UInt32(bitPattern: code))
        case .cannotRead(let code):
            return String(format: "无法读取 HID Report 3 (0x%08x)", UInt32(bitPattern: code))
        case .invalidReport(let bytes):
            return "HID Report 3 内容无法解析：\(bytes.map { String(format: "%02x", $0) }.joined(separator: " "))"
        }
    }
}

public struct K3HIDReader {
    public static let productName = "Keychron K3"
    public static let bluetoothTransport = "Bluetooth"

    public init() {}

    public var access: K3HIDAccess {
        switch IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) {
        case kIOHIDAccessTypeGranted:
            return .granted
        case kIOHIDAccessTypeDenied:
            return .denied
        default:
            return .unknown
        }
    }

    /// macOS displays its own Input Monitoring prompt when access is undecided.
    @discardableResult
    public func requestAccess() -> Bool {
        IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
    }

    public func read() throws -> K3BatteryReading {
        guard access != .denied else {
            throw K3HIDError.accessDenied
        }

        let manager = IOHIDManagerCreate(
            kCFAllocatorDefault,
            IOOptionBits(kIOHIDOptionsTypeNone)
        )
        let matching: [String: Any] = [
            kIOHIDProductKey as String: Self.productName,
            kIOHIDTransportKey as String: Self.bluetoothTransport
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)

        let managerResult = IOHIDManagerOpen(
            manager,
            IOOptionBits(kIOHIDOptionsTypeNone)
        )
        guard managerResult == kIOReturnSuccess else {
            if managerResult == kIOReturnNotPermitted {
                throw K3HIDError.accessDenied
            }
            throw K3HIDError.cannotOpen(managerResult)
        }
        defer {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        }

        let device = findDevice(in: manager)
        guard let device else {
            throw K3HIDError.notFound
        }

        let openResult = IOHIDDeviceOpen(
            device,
            IOOptionBits(kIOHIDOptionsTypeNone)
        )
        guard openResult == kIOReturnSuccess else {
            throw K3HIDError.cannotOpen(openResult)
        }
        defer {
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
        }

        var report = [UInt8](repeating: 0, count: 64)
        var reportLength = CFIndex(report.count)
        let readResult = IOHIDDeviceGetReport(
            device,
            kIOHIDReportTypeInput,
            CFIndex(K3ReportParser.reportID),
            &report,
            &reportLength
        )
        guard readResult == kIOReturnSuccess else {
            throw K3HIDError.cannotRead(readResult)
        }

        let received = Array(report.prefix(max(0, Int(reportLength))))
        guard let reading = K3ReportParser.parse(received) else {
            throw K3HIDError.invalidReport(received)
        }
        return reading
    }

    private func findDevice(in manager: IOHIDManager) -> IOHIDDevice? {
        for _ in 0..<4 {
            if let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>,
               devices.isEmpty == false {
                return devices.first {
                    let product = IOHIDDeviceGetProperty(
                        $0,
                        kIOHIDProductKey as CFString
                    ) as? String
                    let transport = IOHIDDeviceGetProperty(
                        $0,
                        kIOHIDTransportKey as CFString
                    ) as? String
                    return product == Self.productName &&
                        transport == Self.bluetoothTransport
                }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return nil
    }
}
