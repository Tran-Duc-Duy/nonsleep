#!/usr/bin/env swift
// Renders the NonSleep app icon: a silver MacBook closed all the way on a dark matte tile, a
// glowing sparkle above it (the agent at work), and a teal status LED (still running).
// The laptop is a projected 3D box, so every face lines up and can be shaded along its own axes.
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

func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint { p(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t) }
func polygon(_ points: [CGPoint]) -> CGPath {
    let path = CGMutablePath()
    path.addLines(between: points)
    path.closeSubpath()
    return path
}

// Orthographic camera: turn the laptop by `yaw`, look down on it by `pitch`.
let yaw = 24.0 * .pi / 180, pitch = 30.0 * .pi / 180
let scale: CGFloat = 600, origin = p(505, 700)
func project(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat) -> CGPoint {
    let xr = x * cos(yaw) + z * sin(yaw)
    let zr = -x * sin(yaw) + z * cos(yaw)
    let up = y * cos(pitch) - zr * sin(pitch)
    return p(origin.x + xr * scale, origin.y - up * scale)
}

let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!
// Work top-down like a design tool.
ctx.translateBy(x: 0, y: CGFloat(size))
ctx.scaleBy(x: 1, y: -1)

// macOS icon grid: 824pt tile centered on a 1024 canvas, with a soft drop shadow.
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = CGPath(roundedRect: tile, cornerWidth: 186, cornerHeight: 186, transform: nil)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 18), blur: 40, color: rgb(0x000000, 0.35))
ctx.addPath(tilePath)
ctx.setFillColor(rgb(0x16171B))
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(tilePath)
ctx.clip()

// Matte charcoal with a studio light from the top left.
ctx.drawLinearGradient(
    gradient([(0x2E2F35, 1, 0), (0x18191D, 1, 0.55), (0x0C0D10, 1, 1)]),
    start: p(260, 100), end: p(700, 924), options: []
)
ctx.drawRadialGradient(
    gradient([(0x60626E, 0.30, 0), (0x60626E, 0, 1)]),
    startCenter: p(300, 240), startRadius: 0, endCenter: p(300, 240), endRadius: 560, options: []
)

// Closed laptop: a thin box, width 1 × depth 0.7 × height h; the lid meets the base at `seam`.
let w: CGFloat = 0.5, depth: CGFloat = 0.35, h: CGFloat = 0.052, seam = h * 0.45
let top = [project(-w, h, -depth), project(w, h, -depth), project(w, h, depth), project(-w, h, depth)]
let front = [project(-w, h, depth), project(w, h, depth), project(w, 0, depth), project(-w, 0, depth)]
let left = [project(-w, h, -depth), project(-w, h, depth), project(-w, 0, depth), project(-w, 0, -depth)]

func shade(_ face: [CGPoint], _ stops: [(UInt32, CGFloat, CGFloat)], from: CGPoint, to: CGPoint) {
    ctx.saveGState()
    ctx.addPath(polygon(face))
    ctx.clip()
    ctx.drawLinearGradient(gradient(stops), start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()
}

// Contact shadow on the desk.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 10, height: 30), blur: 70, color: rgb(0x000000, 0.85))
ctx.addPath(polygon([project(-w, 0, -depth), project(w, 0, -depth), project(w, 0, depth), project(-w, 0, depth)]))
ctx.setFillColor(rgb(0x000000))
ctx.fillPath()
ctx.restoreGState()

// Front and left faces, top to bottom: lit lid lip, dark seam, base. The left side is in shade.
shade(front, [(0xDADDE4, 1, 0), (0xA9ACB6, 1, 0.52), (0x2C2E33, 1, 0.55), (0x2C2E33, 1, 0.58), (0x8E919B, 1, 0.62), (0x5B5E66, 1, 1)],
      from: project(0, h, depth), to: project(0, 0, depth))
shade(left, [(0xC8C8C8, 1, 0), (0x888888, 1, 0.52), (0x2C2E33, 1, 0.55), (0x2C2E33, 1, 0.58), (0x888888, 1, 0.62), (0x484848, 1, 1)],
      from: project(-w, h, 0), to: project(-w, 0, 0))

// Lid: darker at the back, a broad specular sweep toward the front, and the sparkle's light on it.
shade(top, [(0x6E717B, 1, 0), (0xA7AAB4, 1, 0.42), (0xEEF0F4, 1, 0.70), (0xBFC2CB, 1, 1)],
      from: project(-w, h, -depth), to: project(w * 0.6, h, depth))
ctx.saveGState()
ctx.addPath(polygon(top))
ctx.clip()
let glowOnLid = project(0.05, h, -0.1)
ctx.drawRadialGradient(
    gradient([(0x9B8CFF, 0.42, 0), (0x9B8CFF, 0, 1)]),
    startCenter: glowOnLid, startRadius: 0, endCenter: glowOnLid, endRadius: 240, options: []
)
ctx.restoreGState()

ctx.setLineCap(.round)

// Crisp highlight along the lid's front edge.
ctx.setLineWidth(2.5)
ctx.setStrokeColor(rgb(0xFFFFFF, 0.95))
ctx.move(to: top[3]); ctx.addLine(to: top[2]); ctx.strokePath()

// Lid/base seam: a dark gap with a lit edge just under it, along the left and front sides.
for (offset, color, width) in [(CGFloat(0), rgb(0x1E2024, 0.95), CGFloat(3.5)), (2.5, rgb(0xFFFFFF, 0.25), 1.5)] {
    let back = project(-w, seam, -depth), corner = project(-w, seam, depth), right = project(w, seam, depth)
    ctx.setLineWidth(width)
    ctx.setStrokeColor(color)
    ctx.move(to: p(back.x, back.y + offset))
    ctx.addLine(to: p(corner.x, corner.y + offset))
    ctx.addLine(to: p(right.x, right.y + offset))
    ctx.strokePath()
}

// Thumb notch in the lid's front lip.
let notch = CGMutablePath()
let notchBottom = project(0, h - (h - seam) * 0.8, depth)
notch.move(to: project(-0.06, h, depth))
notch.addQuadCurve(to: project(0.06, h, depth), control: p(notchBottom.x, notchBottom.y + 6))
notch.closeSubpath()
ctx.addPath(notch)
ctx.setFillColor(rgb(0x3A3C42, 0.9))
ctx.fillPath()

// Two USB-C ports on the left side of the base.
ctx.setLineWidth(6)
ctx.setStrokeColor(rgb(0x1A1B1F))
for z in [CGFloat(-0.12), -0.02] {
    ctx.move(to: project(-w, seam * 0.5, z)); ctx.addLine(to: project(-w, seam * 0.5, z + 0.05)); ctx.strokePath()
}

// Softer highlight along the lid's left edge.
ctx.setLineWidth(2)
ctx.setStrokeColor(rgb(0xFFFFFF, 0.6))
ctx.move(to: top[0]); ctx.addLine(to: top[3]); ctx.strokePath()

// Status LED on the base's front edge: still running with the lid closed.
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 24, color: rgb(0x2EF2B8, 1))
ctx.setLineWidth(7)
ctx.setStrokeColor(rgb(0x8CFFE0))
ctx.move(to: project(-0.36, seam * 0.5, depth)); ctx.addLine(to: project(-0.30, seam * 0.5, depth)); ctx.strokePath()
ctx.restoreGState()

// The sparkle: a four-point star with concave sides, glowing blue → violet.
let center = p(560, 330), r: CGFloat = 96
let tips = [p(center.x, center.y - r), p(center.x + r * 0.8, center.y), p(center.x, center.y + r), p(center.x - r * 0.8, center.y)]
let star = CGMutablePath()
star.move(to: tips[0])
for i in 0..<4 {
    let next = tips[(i + 1) % 4]
    star.addQuadCurve(to: next, control: lerp(center, lerp(tips[i], next, 0.5), 0.16))
}
star.closeSubpath()
ctx.drawRadialGradient(
    gradient([(0x7D7BFF, 0.40, 0), (0x7D7BFF, 0.10, 0.45), (0x7D7BFF, 0, 1)]),
    startCenter: center, startRadius: 0, endCenter: center, endRadius: 320, options: []
)
for (blur, alpha) in [(CGFloat(90), CGFloat(0.9)), (34, 0.95)] {
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: blur, color: rgb(0x8F7BFF, alpha))
    ctx.addPath(star)
    ctx.setFillColor(rgb(0x9A8CFF))
    ctx.fillPath()
    ctx.restoreGState()
}
ctx.saveGState()
ctx.addPath(star)
ctx.clip()
ctx.drawLinearGradient(
    gradient([(0x8FB4FF, 1, 0), (0xA79BFF, 1, 0.5), (0xD08CFF, 1, 1)]),
    start: p(center.x - r, center.y - r), end: p(center.x + r, center.y + r), options: []
)
ctx.drawRadialGradient(
    gradient([(0xFFFFFF, 0.9, 0), (0xFFFFFF, 0, 1)]),
    startCenter: center, startRadius: 0, endCenter: center, endRadius: r * 0.5, options: []
)
ctx.restoreGState()

// Glass rim: subtle inner stroke for depth.
ctx.restoreGState()
ctx.addPath(tilePath)
ctx.setLineWidth(3)
ctx.setStrokeColor(rgb(0xFFFFFF, 0.10))
ctx.strokePath()

let image = ctx.makeImage()!
let url = URL(fileURLWithPath: output)
let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("could not write \(output)") }
print(output)
