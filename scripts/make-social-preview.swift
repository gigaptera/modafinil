import AppKit

let W = 1280, H = 640
let scale: CGFloat = 2

let pxW = Int(CGFloat(W) * scale), pxH = Int(CGFloat(H) * scale)
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: pxW, pixelsHigh: pxH,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: CGFloat(W), height: CGFloat(H))

let gfx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = gfx

let h = CGFloat(H)
let w = CGFloat(W)

// Background
NSColor(red: 0x0d/255, green: 0x0d/255, blue: 0x0d/255, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: W, height: H)).fill()

// Subtle vertical divider between text and icon zones
NSColor(red: 0x22/255, green: 0x22/255, blue: 0x22/255, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: w * 0.54, y: h * 0.12, width: 1, height: h * 0.76)).fill()

let primary   = NSColor(red: 0xF2/255, green: 0xF1/255, blue: 0xEE/255, alpha: 1)
let muted     = NSColor(red: 0x55/255, green: 0x55/255, blue: 0x55/255, alpha: 1)
let secondary = NSColor(red: 0x88/255, green: 0x88/255, blue: 0x88/255, alpha: 1)

func put(_ text: String, x: CGFloat, topY: CGFloat, font: NSFont, color: NSColor) {
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let astr = NSAttributedString(string: text, attributes: attrs)
    let sz = astr.size()
    astr.draw(at: NSPoint(x: x, y: h - topY - sz.height))
}

let lx: CGFloat = 88

// Kicker
put("MODAFINIL FOR MAC", x: lx, topY: 108,
    font: .systemFont(ofSize: 12, weight: .medium), color: muted)

// Title
let titleFont = NSFont.systemFont(ofSize: 86, weight: .black)
put("Keep your",  x: lx, topY: 148, font: titleFont, color: primary)
put("Mac awake.", x: lx, topY: 248, font: titleFont, color: primary)

// Subtitle
put("While your AI agents run.",
    x: lx, topY: 374,
    font: .systemFont(ofSize: 16, weight: .regular), color: secondary)
put("Right from your menu bar.",
    x: lx, topY: 400,
    font: .systemFont(ofSize: 16, weight: .semibold), color: primary)

// Bottom strip — divider
NSColor(red: 0x1e/255, green: 0x1e/255, blue: 0x1e/255, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: W, height: 72)).fill()

// URL + version in bottom strip
put("gigaptera.com/modafinil",
    x: lx, topY: CGFloat(H) - 46,
    font: .systemFont(ofSize: 13, weight: .regular), color: muted)
put("Version 1.0  ·  macOS 14+  ·  Free",
    x: lx + 260, topY: CGFloat(H) - 46,
    font: .systemFont(ofSize: 13, weight: .regular), color: muted)

// App icon — right zone centered
let iconPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1]
    : "/Users/yuget/Gigaptera/modafinil/modafinil.icon/Assets/modafinil-icon.png"
if let icon = NSImage(contentsOfFile: iconPath) {
    let sz: CGFloat = 280
    let cx: CGFloat = w * 0.54 + (w * 0.46) / 2  // center of right zone
    let cy: CGFloat = (h - 72) / 2 + 10           // center vertically above bottom strip
    let iconRect = NSRect(x: cx - sz/2, y: cy - sz/2, width: sz, height: sz)

    // Shadow
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(white: 0, alpha: 0.5)
    shadow.shadowBlurRadius = 40
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()

    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: iconRect, xRadius: 62, yRadius: 62).addClip()
    icon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
}

NSGraphicsContext.restoreGraphicsState()

let outPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2]
    : "modafinil-social-preview.png"
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: outPath))
print("saved \(outPath) (\(pxW)×\(pxH)px)")
