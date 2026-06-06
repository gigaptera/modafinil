import AppKit

extension NSImage {
    static let pillOff: NSImage = makePill(active: false)
    static let pillOn: NSImage  = makePill(active: true)

    private static func makePill(active: Bool) -> NSImage {
        let size = CGSize(width: 20, height: 20)
        let img = NSImage(size: size, flipped: false) { rect in
            let lw: CGFloat = 1.5
            let r: CGFloat  = 5.5
            let cx = rect.midX, cy = rect.midY

            NSColor.black.setFill()

            if active {
                let offsetX: CGFloat = 3.0
                let tilt: CGFloat    = 20
                let overallTilt: CGFloat = -12

                NSGraphicsContext.saveGraphicsState()
                let ot = NSAffineTransform()
                ot.translateX(by: cx, yBy: cy)
                ot.rotate(byDegrees: overallTilt)
                ot.translateX(by: -cx, yBy: -cy)
                ot.concat()

                NSGraphicsContext.saveGraphicsState()
                let lt = NSAffineTransform()
                lt.translateX(by: cx - offsetX, yBy: cy)
                lt.rotate(byDegrees: tilt)
                lt.concat()
                halfPath(side: .left, r: r).fill()
                NSGraphicsContext.restoreGraphicsState()

                NSGraphicsContext.saveGraphicsState()
                let rt = NSAffineTransform()
                rt.translateX(by: cx + offsetX, yBy: cy)
                rt.rotate(byDegrees: -tilt)
                rt.concat()
                halfPath(side: .right, r: r).fill()
                NSGraphicsContext.restoreGraphicsState()

                NSGraphicsContext.restoreGraphicsState()

            } else {
                let oval = NSBezierPath(ovalIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
                oval.fill()

                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current?.cgContext.setBlendMode(.clear)
                let score = NSBezierPath()
                score.lineWidth = lw
                score.lineCapStyle = .round
                score.move(to: CGPoint(x: cx, y: cy - r * 0.85))
                score.line(to: CGPoint(x: cx, y: cy + r * 0.85))
                score.stroke()
                NSGraphicsContext.restoreGraphicsState()
            }
            return true
        }
        img.isTemplate = true
        return img
    }

    private enum Side { case left, right }

    private static func halfPath(side: Side, r: CGFloat) -> NSBezierPath {
        let p = NSBezierPath()
        switch side {
        case .left:
            p.move(to: CGPoint(x: 0, y: r))
            p.appendArc(withCenter: .zero, radius: r, startAngle: 90, endAngle: 270, clockwise: false)
            p.close()
        case .right:
            p.move(to: CGPoint(x: 0, y: -r))
            p.appendArc(withCenter: .zero, radius: r, startAngle: 270, endAngle: 90, clockwise: false)
            p.close()
        }
        return p
    }
}
