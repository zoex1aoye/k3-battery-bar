#!/usr/bin/env swift

import AppKit
import CoreText
import Foundation

guard CommandLine.arguments.count >= 2 else {
    fputs("usage: generate-app-icon.swift <iconset-dir> [preview.png]\n", stderr)
    exit(2)
}

let outputDirectory = URL(
    fileURLWithPath: CommandLine.arguments[1],
    isDirectory: true
)
try FileManager.default.createDirectory(
    at: outputDirectory,
    withIntermediateDirectories: true
)

let iconFiles: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for iconFile in iconFiles {
    let data = renderIcon(pixelSize: iconFile.pixels)
    try data.write(to: outputDirectory.appendingPathComponent(iconFile.name))
}

if CommandLine.arguments.count >= 3 {
    let previewURL = URL(fileURLWithPath: CommandLine.arguments[2])
    try renderIcon(pixelSize: 1024).write(to: previewURL)
}

func renderIcon(pixelSize: Int) -> Data {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    bitmap.size = NSSize(width: pixelSize, height: pixelSize)

    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    let scale = CGFloat(pixelSize) / 1024
    context.cgContext.scaleBy(x: scale, y: scale)

    drawBackground()
    drawKeyboard(pixelScale: scale)

    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}

func drawBackground() {
    let frame = NSRect(x: 76, y: 76, width: 872, height: 872)
    let shape = NSBezierPath(
        roundedRect: frame,
        xRadius: 205,
        yRadius: 205
    )

    NSGraphicsContext.saveGraphicsState()
    shape.addClip()

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.18, green: 0.20, blue: 0.23, alpha: 1),
        NSColor(calibratedRed: 0.055, green: 0.063, blue: 0.075, alpha: 1)
    ])!
    gradient.draw(in: shape, angle: -90)

    let glow = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.10),
        NSColor.white.withAlphaComponent(0)
    ])!
    glow.draw(
        in: NSBezierPath(
            ovalIn: NSRect(x: 92, y: 520, width: 760, height: 610)
        ),
        relativeCenterPosition: NSPoint(x: -0.25, y: 0.35)
    )

    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.14).setStroke()
    shape.lineWidth = 4
    shape.stroke()
}

func drawKeyboard(pixelScale: CGFloat) {
    let keyboardColor = NSColor(
        calibratedRed: 0.96,
        green: 0.97,
        blue: 0.98,
        alpha: 1
    )
    keyboardColor.setFill()
    keyboardColor.setStroke()

    let body = NSRect(x: 182, y: 262, width: 660, height: 500)
    let outline = NSBezierPath(
        roundedRect: body,
        xRadius: 78,
        yRadius: 78
    )
    outline.lineWidth = max(34, 1.15 / pixelScale)
    outline.stroke()

    let keyWidth: CGFloat = 70
    let keyHeight: CGFloat = 44
    let gap: CGFloat = 52
    let rowStart: CGFloat = 294
    for column in 0..<4 {
        let x = rowStart + CGFloat(column) * (keyWidth + gap)
        roundedKey(
            NSRect(x: x, y: 646, width: keyWidth, height: keyHeight),
            radius: 13
        )
    }

    roundedKey(
        NSRect(x: 294, y: 348, width: 50, height: 48),
        radius: 13
    )
    roundedKey(
        NSRect(x: 362, y: 348, width: 228, height: 48),
        radius: 13
    )

    let commandFrame = NSRect(x: 632, y: 326, width: 178, height: 178)
    let commandShape = NSBezierPath(
        roundedRect: commandFrame,
        xRadius: 30,
        yRadius: 30
    )
    let commandGradient = NSGradient(colors: [
        NSColor(calibratedRed: 1.0, green: 0.63, blue: 0.075, alpha: 1),
        NSColor(calibratedRed: 1.0, green: 0.73, blue: 0.22, alpha: 1)
    ])!
    commandGradient.draw(in: commandShape, angle: -90)

    drawCommandGlyph(in: commandFrame, color: .black, fontSize: 148)
}

func roundedKey(_ rect: NSRect, radius: CGFloat) {
    NSBezierPath(
        roundedRect: rect,
        xRadius: radius,
        yRadius: radius
    ).fill()
}

func drawCommandGlyph(in frame: NSRect, color: NSColor, fontSize: CGFloat) {
    let font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
    let coreTextFont = CTFontCreateWithName(
        font.fontName as CFString,
        font.pointSize,
        nil
    )
    var characters = Array("⌘".utf16)
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
    guard let centeredPath = glyphPath.copy(using: &transform),
          let context = NSGraphicsContext.current?.cgContext else {
        return
    }

    context.setFillColor(color.cgColor)
    context.addPath(centeredPath)
    context.fillPath()
}
