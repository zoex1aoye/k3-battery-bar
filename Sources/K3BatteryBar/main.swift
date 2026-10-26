import AppKit
import K3BatteryCore

if let previewIndex = CommandLine.arguments.firstIndex(of: "--render-icon") {
    let outputPath: String
    if CommandLine.arguments.indices.contains(previewIndex + 1) {
        outputPath = CommandLine.arguments[previewIndex + 1]
    } else {
        outputPath = "/tmp/k3-battery-icon.png"
    }

    do {
        let reading = try K3HIDReader().read()
        guard let data = MenuBarIcon.previewPNG(percent: reading.percent) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: URL(fileURLWithPath: outputPath))
        print(outputPath)
        exit(0)
    } catch {
        fputs("render failed: \(error.localizedDescription)\n", stderr)
        exit(2)
    }
}

if CommandLine.arguments.contains("--diagnose") {
    let reader = K3HIDReader()
    print("access: \(reader.access.rawValue)")

    if CommandLine.arguments.contains("--request-access"),
       reader.access != .granted {
        print("requesting input monitoring access…")
        _ = reader.requestAccess()
        Thread.sleep(forTimeInterval: 0.5)
    }

    do {
        let reading = try reader.read()
        print("battery: \(reading.percent)%")
        print("address: \(reading.address ?? "unknown")")
        exit(0)
    } catch {
        fputs("error: \(error.localizedDescription)\n", stderr)
        exit(2)
    }
}

let application = NSApplication.shared
let appDelegate = AppDelegate()

application.setActivationPolicy(.accessory)
application.delegate = appDelegate
application.run()
