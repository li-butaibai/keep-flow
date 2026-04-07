import AppKit

enum MenuBarIcon {
    static func makeImage(size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let strokeColor = NSColor.labelColor
        strokeColor.setStroke()
        strokeColor.setFill()

        let inset = size * 0.16
        let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)

        let path = NSBezierPath()
        path.lineWidth = max(1.7, size * 0.11)
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        path.move(to: NSPoint(x: rect.minX + rect.width * 0.78, y: rect.maxY))
        path.curve(
            to: NSPoint(x: rect.minX + rect.width * 0.34, y: rect.maxY - rect.height * 0.20),
            controlPoint1: NSPoint(x: rect.minX + rect.width * 0.62, y: rect.maxY),
            controlPoint2: NSPoint(x: rect.minX + rect.width * 0.42, y: rect.maxY - rect.height * 0.01)
        )
        path.curve(
            to: NSPoint(x: rect.minX + rect.width * 0.28, y: rect.minY + rect.height * 0.50),
            controlPoint1: NSPoint(x: rect.minX + rect.width * 0.28, y: rect.maxY - rect.height * 0.34),
            controlPoint2: NSPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.63)
        )
        path.curve(
            to: NSPoint(x: rect.minX + rect.width * 0.66, y: rect.minY + rect.height * 0.39),
            controlPoint1: NSPoint(x: rect.minX + rect.width * 0.37, y: rect.minY + rect.height * 0.31),
            controlPoint2: NSPoint(x: rect.minX + rect.width * 0.56, y: rect.minY + rect.height * 0.25)
        )
        path.curve(
            to: NSPoint(x: rect.minX + rect.width * 0.57, y: rect.minY),
            controlPoint1: NSPoint(x: rect.minX + rect.width * 0.78, y: rect.minY + rect.height * 0.53),
            controlPoint2: NSPoint(x: rect.minX + rect.width * 0.72, y: rect.minY + rect.height * 0.08)
        )

        path.stroke()

        let dotSize = max(2.6, size * 0.18)
        let dotRect = NSRect(
            x: rect.maxX - dotSize * 1.2,
            y: rect.minY + rect.height * 0.10,
            width: dotSize,
            height: dotSize
        )
        NSBezierPath(ovalIn: dotRect).fill()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
