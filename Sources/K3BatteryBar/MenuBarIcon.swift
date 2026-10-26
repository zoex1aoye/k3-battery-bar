import AppKit
import CoreText

enum MenuBarIcon {
    private static let imageHeight: CGFloat = 18
    private static let fixedWidth: CGFloat = 22

    static func make(
        percent: Int?,
        primaryColor: NSColor = .labelColor
    ) -> NSImage {
        let size = NSSize(width: fixedWidth, height: imageHeight)
        let image = NSImage(size: size, flipped: false) { rect in
            drawKeyboard(
                percent: percent,
                primaryColor: primaryColor,
                in: rect
            )
            return true
        }
        image.isTemplate = false
        image.accessibilityDescription = percent.map { "Keychron K3 电量 \($0)%" }
            ?? "Keychron K3 未连接"
        return image
    }

    static func previewPNG(percent: Int?, scale: CGFloat = 8) -> Data? {
        let image = make(percent: percent, primaryColor: .white)
        let logicalSize = image.size
        let pixelWidth = Int(logicalSize.width * scale)
        let pixelHeight = Int(logicalSize.height * scale)

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelWidth,
            pixelsHigh: pixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            return nil
        }

        bitmap.size = logicalSize
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        context.cgContext.scaleBy(x: scale, y: scale)
        NSColor(calibratedWhite: 0.12, alpha: 1).setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: logicalSize)).fill()
        image.draw(
            in: NSRect(origin: .zero, size: logicalSize),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
        NSGraphicsContext.restoreGraphicsState()

        return bitmap.representation(using: .png, properties: [:])
    }

    private static func drawKeyboard(
        percent: Int?,
        primaryColor: NSColor,
        in rect: NSRect
    ) {
        let primary = primaryColor
        primary.setFill()
        primary.setStroke()

        let body = NSRect(
            x: 1,
            y: 1.5,
            width: rect.width - 2,
            height: 15
        )
        let outline = NSBezierPath(
            roundedRect: body,
            xRadius: 3.4,
            yRadius: 3.4
        )
        outline.lineWidth = 1.2
        outline.stroke()

        let keyWidth: CGFloat = 2.2
        let keyHeight: CGFloat = 1.55
        let gap: CGFloat = 1.8
        let rowStart: CGFloat = 3.8

        for column in 0..<4 {
            let x = rowStart + CGFloat(column) * (keyWidth + gap)
            fillKey(NSRect(x: x, y: 12.7, width: keyWidth, height: keyHeight))
        }

        fillKey(NSRect(x: 3.8, y: 4.55, width: 2.3, height: 1.8))
        fillKey(NSRect(x: 6.9, y: 4.55, width: 5.6, height: 1.8))

        let commandFrame = NSRect(x: 13.05, y: 2.75, width: 6.55, height: 6.55)
        if let percent {
            let accent = color(for: percent)
            accent.setFill()
            NSBezierPath(
                roundedRect: commandFrame,
                xRadius: 1.15,
                yRadius: 1.15
            ).fill()
            drawCommandSymbol(
                in: commandFrame,
                color: commandGlyphColor(for: percent)
            )
        } else {
            let outline = NSBezierPath(
                roundedRect: commandFrame,
                xRadius: 1.15,
                yRadius: 1.15
            )
            outline.lineWidth = 1.05
            outline.stroke()
            drawCommandSymbol(in: commandFrame, color: primary)
        }
    }

    private static func fillKey(_ rect: NSRect) {
        NSBezierPath(
            roundedRect: rect,
            xRadius: 0.45,
            yRadius: 0.45
        ).fill()
    }

    private static func drawCommandSymbol(
        in frame: NSRect,
        color: NSColor
    ) {
        let symbol = "⌘"
        let font = NSFont.systemFont(ofSize: 5.55, weight: .semibold)
        let coreTextFont = CTFontCreateWithName(
            font.fontName as CFString,
            font.pointSize,
            nil
        )
        var characters = Array(symbol.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)
        guard CTFontGetGlyphsForCharacters(
            coreTextFont,
            &characters,
            &glyphs,
            characters.count
        ), let glyphPath = CTFontCreatePathForGlyph(
            coreTextFont,
            glyphs[0],
            nil
        ) else {
            return
        }

        let bounds = glyphPath.boundingBoxOfPath
        var transform = CGAffineTransform(
            translationX: frame.midX - bounds.midX,
            y: frame.midY - bounds.midY
        )
        guard let centeredPath = glyphPath.copy(using: &transform) else {
            return
        }
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }

        context.saveGState()
        context.setFillColor(color.cgColor)
        context.addPath(centeredPath)
        context.fillPath()
        context.restoreGState()
    }

    private static func commandGlyphColor(for percent: Int) -> NSColor {
        switch percent {
        case 21...60:
            return .black
        default:
            return .white
        }
    }

    private static func color(for percent: Int) -> NSColor {
        switch percent {
        case 61...:
            return .systemGreen
        case 21...:
            return .systemOrange
        default:
            return .systemRed
        }
    }
}
