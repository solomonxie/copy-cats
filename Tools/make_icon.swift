// Renders the 1024px app icon: swift Tools/make_icon.swift <output.png>
import AppKit

let size = 1024.0
let output = CommandLine.arguments.dropFirst().first ?? "AppIcon.png"
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

// background gradient
let gradient = CGGradient(colorsSpace: space, colors: [color(0xFF9A3C), color(0xFF4F7B)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])

func card(_ rect: CGRect, fill: CGColor, ears: Bool) {
    let path = CGMutablePath()
    path.addRoundedRect(in: rect, cornerWidth: 70, cornerHeight: 70)
    if ears {
        let top = rect.maxY - 40
        let earW = rect.width * 0.26, earH = rect.width * 0.24
        for left in [rect.minX + 30, rect.maxX - 30 - earW] {
            // same winding as the rounded rect so the overlap stays filled
            path.move(to: CGPoint(x: left + earW, y: top))
            path.addLine(to: CGPoint(x: left + (left < rect.midX ? earW * 0.2 : earW * 0.8), y: top + earH + 30))
            path.addLine(to: CGPoint(x: left, y: top))
            path.closeSubpath()
        }
    }
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 40, color: color(0x7A1030, 0.35))
    ctx.addPath(path)
    ctx.setFillColor(fill)
    ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
}

// back cards = history, front card = cat
card(CGRect(x: 300, y: 250, width: 500, height: 520), fill: color(0xFFFFFF, 0.45), ears: false)
card(CGRect(x: 262, y: 215, width: 500, height: 520), fill: color(0xFFFFFF, 0.7), ears: false)
let front = CGRect(x: 224, y: 180, width: 500, height: 520)
card(front, fill: color(0xFFFFFF), ears: true)

// eyes
ctx.setFillColor(color(0x3A2340))
for x in [front.minX + 150, front.maxX - 150] {
    ctx.fillEllipse(in: CGRect(x: x - 32, y: front.maxY - 190, width: 64, height: 76))
}
// nose
ctx.setFillColor(color(0xFF4F7B))
let nose = CGMutablePath()
nose.move(to: CGPoint(x: front.midX - 26, y: front.maxY - 225))
nose.addLine(to: CGPoint(x: front.midX + 26, y: front.maxY - 225))
nose.addLine(to: CGPoint(x: front.midX, y: front.maxY - 255))
nose.closeSubpath()
ctx.addPath(nose)
ctx.fillPath()

// text lines
ctx.setFillColor(color(0xE6DDE8))
for (i, width) in [300.0, 360.0, 240.0].enumerated() {
    let rect = CGRect(x: front.minX + 70, y: front.minY + 210 - Double(i) * 62, width: width, height: 30)
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: 15, cornerHeight: 15, transform: nil))
    ctx.fillPath()
}

let image = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
print("wrote \(output)")
