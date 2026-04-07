import AppKit

enum MenuBarIcon {
    static func makeImage(size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let strokeColor = NSColor.labelColor
        strokeColor.setStroke()
        strokeColor.setFill()

        let inset = size * 0.12
        let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)

        let path = NSBezierPath()
        path.lineWidth = max(1.8, size * 0.12)
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        path.move(to: NSPoint(x: rect.minX + rect.width * 0.82, y: rect.maxY - rect.height * 0.02))
        path.curve(
            to: NSPoint(x: rect.minX + rect.width * 0.26, y: rect.minY + rect.height * 0.56),
            controlPoint1: NSPoint(x: rect.minX + rect.width * 0.63, y: rect.maxY + rect.height * 0.04),
            controlPoint2: NSPoint(x: rect.minX + rect.width * 0.33, y: rect.minY + rect.height * 0.78)
        )
        path.curve(
            to: NSPoint(x: rect.minX + rect.width * 0.55, y: rect.minY + rect.height * 0.43),
            controlPoint1: NSPoint(x: rect.minX + rect.width * 0.33, y: rect.minY + rect.height * 0.34),
            controlPoint2: NSPoint(x: rect.minX + rect.width * 0.48, y: rect.minY + rect.height * 0.43)
        )
        path.curve(
            to: NSPoint(x: rect.minX + rect.width * 0.40, y: rect.minY + rect.height * 0.12),
            controlPoint1: NSPoint(x: rect.minX + rect.width * 0.66, y: rect.minY + rect.height * 0.43),
            controlPoint2: NSPoint(x: rect.minX + rect.width * 0.54, y: rect.minY + rect.height * 0.17)
        )

        path.stroke()

        let tail = NSBezierPath()
        tail.lineWidth = path.lineWidth
        tail.lineCapStyle = .round
        tail.move(to: NSPoint(x: rect.minX + rect.width * 0.39, y: rect.minY + rect.height * 0.12))
        tail.curve(
            to: NSPoint(x: rect.minX + rect.width * 0.14, y: rect.minY + rect.height * 0.04),
            controlPoint1: NSPoint(x: rect.minX + rect.width * 0.31, y: rect.minY + rect.height * 0.07),
            controlPoint2: NSPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.02)
        )
        tail.stroke()

        let dotSize = max(2.8, size * 0.19)
        let dotRect = NSRect(
            x: rect.minX + rect.width * 0.64,
            y: rect.minY + rect.height * 0.09,
            width: dotSize,
            height: dotSize
        )
        NSBezierPath(ovalIn: dotRect).fill()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
