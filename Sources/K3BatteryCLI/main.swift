import Foundation
import K3BatteryCore

let reader = K3HIDReader()

if CommandLine.arguments.contains("--request-access"),
   reader.access != .granted {
    print("正在请求输入监控权限…")
    _ = reader.requestAccess()
    Thread.sleep(forTimeInterval: 0.5)
}

do {
    let reading = try reader.read()
    let address = reading.address ?? "未知"
    print("Keychron K3: \(reading.percent)%")
    print("地址: \(address)")
} catch {
    fputs("读取失败：\(error.localizedDescription)\n", stderr)
    if reader.access != .granted {
        fputs(
            "请在“系统设置 → 隐私与安全性 → 输入监控”中允许当前终端或 K3BatteryBar，然后重试。\n",
            stderr
        )
    }
    exit(2)
}
