import AppKit
import K3BatteryCore

final class StatusBarController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let reader = K3HIDReader()
    private let menu = NSMenu()
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    private var timer: Timer?
    private var latestReading: K3BatteryReading?
    private var latestError: Error?

    func start() {
        statusItem.menu = menu
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.toolTip = "Keychron K3 电量"
        showUnavailableState()

        if reader.access == .unknown {
            reader.requestAccess()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.refresh()
            }
        } else {
            refresh()
        }

        timer = Timer.scheduledTimer(
            timeInterval: 30,
            target: self,
            selector: #selector(timerFired),
            userInfo: nil,
            repeats: true
        )
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    @objc private func timerFired() {
        refresh()
    }

    @objc func refresh() {
        do {
            latestReading = try reader.read()
            latestError = nil
            updateAvailableState()
        } catch {
            latestReading = nil
            latestError = error
            showUnavailableState()
        }
        rebuildMenu()
    }

    @objc private func openInputMonitoringSettings() {
        let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
        )!
        NSWorkspace.shared.open(url)
    }

    private func showUnavailableState() {
        statusItem.button?.title = ""
        statusItem.button?.image = MenuBarIcon.make(percent: nil)
        statusItem.button?.contentTintColor = nil
        statusItem.button?.toolTip = "Keychron K3 未连接"
        statusItem.button?.setAccessibilityLabel("Keychron K3 未连接")
    }

    private func updateAvailableState() {
        guard let reading = latestReading else {
            showUnavailableState()
            return
        }

        statusItem.button?.title = ""
        statusItem.button?.image = MenuBarIcon.make(percent: reading.percent)
        statusItem.button?.contentTintColor = nil
        statusItem.button?.toolTip = "Keychron K3 电量 \(reading.percent)%"
        statusItem.button?.setAccessibilityLabel(
            "Keychron K3 电量 \(reading.percent)%"
        )
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        let stateTitle: String
        if latestReading != nil {
            stateTitle = "Keychron K3 · \(latestReading?.percent ?? 0)%"
        } else if reader.access == .denied {
            stateTitle = "Keychron K3 · 需要输入监控权限"
        } else if let hidError = latestError as? K3HIDError {
            switch hidError {
            case .notFound:
                stateTitle = "Keychron K3 · 未连接"
            default:
                stateTitle = "Keychron K3 · 读取失败"
            }
        } else {
            stateTitle = "Keychron K3 · 初始化中"
        }

        let titleItem = NSMenuItem(
            title: stateTitle,
            action: nil,
            keyEquivalent: ""
        )
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        if let reading = latestReading {
            if let address = reading.address {
                let addressItem = NSMenuItem(
                    title: "地址 \(address)",
                    action: nil,
                    keyEquivalent: ""
                )
                addressItem.isEnabled = false
                menu.addItem(addressItem)
            }
            let updatedItem = NSMenuItem(
                title: "更新于 \(timeFormatter.string(from: reading.timestamp))",
                action: nil,
                keyEquivalent: ""
            )
            updatedItem.isEnabled = false
            menu.addItem(updatedItem)
        } else if let latestError {
            let errorItem = NSMenuItem(
                title: latestError.localizedDescription,
                action: nil,
                keyEquivalent: ""
            )
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }

        menu.addItem(.separator())

        let refreshItem = NSMenuItem(
            title: "立即刷新",
            action: #selector(refresh),
            keyEquivalent: "r"
        )
        refreshItem.target = self
        menu.addItem(refreshItem)

        if reader.access != .granted {
            let permissionItem = NSMenuItem(
                title: "打开输入监控权限设置…",
                action: #selector(openInputMonitoringSettings),
                keyEquivalent: ""
            )
            permissionItem.target = self
            menu.addItem(permissionItem)
        }

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "退出 K3BatteryBar",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
    }
}
