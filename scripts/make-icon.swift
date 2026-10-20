#!/usr/bin/env swift
// Renders the NonSleep app icon: night sky, crescent moon, a closed MacBook, and a glowing
// heartbeat above it ("still working with the lid closed").
// Usage: swift scripts/make-icon.swift <output.png>   (1024×1024)
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let output = CommandLine.arguments.dropFirst().first ?? "icon.png"

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255, alpha: alpha
    )
}

func gradient(_ stops: [(UInt32, CGFloat, CGFloat)]) -> CGGradient {
    CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: stops.map { rgb($0.0, $0.1) } as CFArray,
        locations: stops.map(\.2)
    )!
}

let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!
// Work top-down like a design tool.
ctx.translateBy(x: 0, y: CGFloat(size))
ctx.scaleBy(x: 1, y: -1)

// macOS icon grid: 824pt tile centered on a 1024 canvas.
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = CGPath(roundedRect: tile, cornerWidth: 186, cornerHeight: 186, transform: nil)

// Drop shadow under the tile.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 18), blur: 40, color: rgb(0x000000, 0.35))
ctx.addPath(tilePath)
ctx.setFillColor(rgb(0x14163A))
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(tilePath)
ctx.clip()

// Night sky.
ctx.drawLinearGradient(
    gradient([(0x0E1235, 1, 0), (0x24205E, 1, 0.55), (0x3B1E6E, 1, 1)]),
    start: CGPoint(x: 512, y: 100), end: CGPoint(x: 512, y: 924), options: []
)
// Teal aurora glow rising from behind the laptop.
ctx.drawRadialGradient(
    gradient([(0x2EF2B8, 0.42, 0), (0x2EF2B8, 0.12, 0.5), (0x2EF2B8, 0, 1)]),
    startCenter: CGPoint(x: 512, y: 700), startRadius: 0,
    endCenter: CGPoint(x: 512, y: 700), endRadius: 420, options: []
)

// Stars (fixed positions so the icon is reproducible).
let stars: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
    (230, 250, 7, 0.95), (330, 190, 4, 0.7), (420, 300, 5, 0.8), (190, 400, 4, 0.6),
    (560, 210, 3.5, 0.65), (300, 470, 3, 0.5), (470, 420, 3, 0.45), (820, 470, 4, 0.55),
    (760, 560, 3, 0.4), (250, 560, 3, 0.35),
]
for (x, y, r, a) in stars {
    ctx.setShadow(offset: .zero, blur: r * 3, color: rgb(0xFFFFFF, a))
    ctx.setFillColor(rgb(0xFFFFFF, a))
    ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
}
ctx.setShadow(offset: .zero, blur: 0, color: nil)

// Crescent moon: clip to the disc, then clip *out* the offset bite (even-odd against the canvas).
let moon = CGRect(x: 610, y: 175, width: 210, height: 210)
let bite = moon.offsetBy(dx: -62, dy: -34).insetBy(dx: 6, dy: 6)
let crescent = CGMutablePath()
crescent.addRect(CGRect(x: 0, y: 0, width: size, height: size))
crescent.addEllipse(in: bite)
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 70, color: rgb(0xFFE7A0, 0.6))
ctx.beginTransparencyLayer(auxiliaryInfo: nil)
ctx.addEllipse(in: moon)
ctx.clip()
ctx.addPath(crescent)
ctx.clip(using: .evenOdd)
ctx.drawLinearGradient(
    gradient([(0xFFF4C9, 1, 0), (0xFFD27A, 1, 1)]),
    start: CGPoint(x: moon.minX, y: moon.minY), end: CGPoint(x: moon.maxX, y: moon.maxY), options: []
)
ctx.endTransparencyLayer()
ctx.restoreGState()

// Closed MacBook seen from the front: lid slab over a slightly wider base.
let lid = CGRect(x: 232, y: 742, width: 560, height: 46)
let base = CGRect(x: 206, y: 784, width: 612, height: 30)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 22), blur: 36, color: rgb(0x000000, 0.5))
ctx.addPath(CGPath(roundedRect: base, cornerWidth: 15, cornerHeight: 15, transform: nil))
ctx.setFillColor(rgb(0x8E93A8))
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(CGPath(roundedRect: base, cornerWidth: 15, cornerHeight: 15, transform: nil))
ctx.clip()
ctx.drawLinearGradient(
    gradient([(0xC9CDDB, 1, 0), (0x7C8197, 1, 1)]),
    start: CGPoint(x: 0, y: base.minY), end: CGPoint(x: 0, y: base.maxY), options: []
)
ctx.restoreGState()
// Thumb notch on the front edge.
ctx.addPath(CGPath(
    roundedRect: CGRect(x: 462, y: 784, width: 100, height: 12), cornerWidth: 6, cornerHeight: 6, transform: nil
))
ctx.setFillColor(rgb(0x5D6178))
ctx.fillPath()

ctx.saveGState()
ctx.addPath(CGPath(roundedRect: lid, cornerWidth: 18, cornerHeight: 18, transform: nil))
ctx.clip()
ctx.drawLinearGradient(
    gradient([(0xF4F6FB, 1, 0), (0xC3C8D8, 1, 0.6), (0xA9AEC2, 1, 1)]),
    start: CGPoint(x: 0, y: lid.minY), end: CGPoint(x: 0, y: lid.maxY), options: []
)
// Specular highlight along the top edge of the lid.
ctx.setFillColor(rgb(0xFFFFFF, 0.8))
ctx.fill(CGRect(x: lid.minX, y: lid.minY, width: lid.width, height: 4))
ctx.restoreGState()

// Heartbeat: the Mac is still alive under the closed lid.
let pulse = CGMutablePath()
pulse.move(to: CGPoint(x: 230, y: 640))
pulse.addLine(to: CGPoint(x: 400, y: 640))
pulse.addLine(to: CGPoint(x: 440, y: 590))
pulse.addLine(to: CGPoint(x: 490, y: 700))
pulse.addLine(to: CGPoint(x: 548, y: 520))
pulse.addLine(to: CGPoint(x: 596, y: 670))
pulse.addLine(to: CGPoint(x: 628, y: 640))
pulse.addLine(to: CGPoint(x: 794, y: 640))
for (width, blur, alpha) in [(CGFloat(40), CGFloat(50), CGFloat(0.55)), (22, 18, 0.9), (10, 0, 1)] {
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: blur, color: rgb(0x2EF2B8, alpha))
    ctx.addPath(pulse)
    ctx.setLineWidth(width)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setStrokeColor(width > 10 ? rgb(0x2EF2B8, alpha) : rgb(0xE9FFF7))
    ctx.strokePath()
    ctx.restoreGState()
}

// Glass rim: subtle inner stroke for depth.
ctx.restoreGState()
ctx.addPath(tilePath)
ctx.setLineWidth(3)
ctx.setStrokeColor(rgb(0xFFFFFF, 0.14))
ctx.strokePath()

let image = ctx.makeImage()!
let url = URL(fileURLWithPath: output)
let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("could not write \(output)") }
print(output)
