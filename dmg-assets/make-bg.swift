import AppKit

func render(scale: CGFloat, to path: String) {
    let w = 600, h = 400
    let pxW = Int(CGFloat(w) * scale), pxH = Int(CGFloat(h) * scale)

    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pxW, pixelsHigh: pxH,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: w, height: h)

    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx

    // Background
    NSColor(red: 0x0d/255.0, green: 0x0d/255.0, blue: 0x0d/255.0, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: w, height: h)).fill()

    let ink = NSColor(red: 0xf2/255.0, green: 0xf1/255.0, blue: 0xee/255.0, alpha: 1)

    // Arrow (AppKit: origin bottom-left)
    let ay: CGFloat = CGFloat(h) - 175
    ink.setStroke()
    let line = NSBezierPath()
    line.lineWidth = 3
    line.lineCapStyle = .round
    line.move(to: NSPoint(x: 258, y: ay))
    line.line(to: NSPoint(x: 342, y: ay))
    line.stroke()
    ink.setFill()
    let head = NSBezierPath()
    head.move(to: NSPoint(x: 348, y: ay))
    head.line(to: NSPoint(x: 333, y: ay + 8))
    head.line(to: NSPoint(x: 333, y: ay - 8))
    head.close()
    head.fill()

    // Caption
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 24, weight: .semibold),
        .foregroundColor: ink,
        .paragraphStyle: para,
        .kern: 0.3,
    ]
    let text = NSAttributedString(string: "Drag Modafinil to Applications", attributes: attrs)
    let size = text.size()
    let ty: CGFloat = CGFloat(h) - 82 - size.height / 2
    text.draw(in: NSRect(x: 0, y: ty, width: CGFloat(w), height: size.height))

    // Applications folder icon
    let apps = NSWorkspace.shared.icon(forFile: "/Applications")
    let iconSide: CGFloat = 120
    apps.draw(in: NSRect(x: 450 - iconSide / 2,
                         y: CGFloat(h) - 180 - iconSide / 2,
                         width: iconSide, height: iconSide),
              from: .zero, operation: .sourceOver, fraction: 1.0)

    NSGraphicsContext.restoreGraphicsState()

    let png = rep.representation(using: .png, properties: [:])!
    try! png.write(to: URL(fileURLWithPath: path))
    print("wrote \(path) (\(pxW)x\(pxH))")
}

render(scale: 1, to: "dmg-assets/dmg-bg.png")
render(scale: 2, to: "dmg-assets/dmg-bg@2x.png")
