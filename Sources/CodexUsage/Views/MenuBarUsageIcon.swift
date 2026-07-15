import AppKit
import SwiftUI

struct MenuBarUsageIcon: View {
  @Environment(\.colorScheme) private var colorScheme

  let remainingPercent: Int?
  let showsPercentage: Bool

  var body: some View {
    Image(
      nsImage: MenuBarIconRenderer.image(
        remainingPercent: remainingPercent,
        showsPercentage: showsPercentage,
        colorScheme: colorScheme
      )
    )
    .interpolation(.high)
  }
}

private enum MenuBarIconRenderer {
  private static let expandedCanvasSize = NSSize(width: 65, height: 18)
  private static let compactCanvasSize = NSSize(width: 33, height: 18)
  private static let codexRect = NSRect(x: 0, y: 1.5, width: 14, height: 15)
  private static let percentageRect = NSRect(x: 36, y: 3.2, width: 29, height: 11)

  private static let hourglassCenterX: CGFloat = 25
  private static let topY: CGFloat = 15.2
  private static let upperBaseY: CGFloat = 14.2
  private static let neckY: CGFloat = 9
  private static let lowerBaseY: CGFloat = 3.8
  private static let bottomY: CGFloat = 2.8
  private static let leftX: CGFloat = 19.2
  private static let rightX: CGFloat = 30.8

  static func image(
    remainingPercent: Int?,
    showsPercentage: Bool,
    colorScheme: ColorScheme
  ) -> NSImage {
    let isDark = colorScheme == .dark
    let foregroundColor = isDark ? NSColor.white : NSColor.black
    let level = remainingPercent.map { max(0, min(100, $0)) }
    let canvasSize = showsPercentage ? expandedCanvasSize : compactCanvasSize

    let image = NSImage(size: canvasSize, flipped: false) { _ in
      drawCodexMark(color: foregroundColor)
      drawHourglass(level: level, color: foregroundColor)
      if showsPercentage {
        drawPercentage(
          remainingPercent.map { "\($0)%" } ?? "--",
          color: foregroundColor
        )
      }
      return true
    }
    image.isTemplate = false
    return image
  }

  private static func drawCodexMark(color: NSColor) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    drawText(
      ">_",
      in: NSRect(x: codexRect.minX, y: codexRect.minY + 2.3, width: 14, height: 10),
      font: NSFont.monospacedSystemFont(ofSize: 8.2, weight: .bold),
      paragraph: paragraph,
      color: color
    )
  }

  private static func drawHourglass(level: Int?, color: NSColor) {
    let outlineColor = color.withAlphaComponent(0.88)
    let outline = NSBezierPath()
    outline.lineWidth = 0.9
    outline.lineCapStyle = .round
    outline.lineJoinStyle = .round

    outline.move(to: NSPoint(x: leftX - 0.4, y: topY))
    outline.line(to: NSPoint(x: rightX + 0.4, y: topY))
    outline.move(to: NSPoint(x: leftX - 0.4, y: bottomY))
    outline.line(to: NSPoint(x: rightX + 0.4, y: bottomY))

    outline.move(to: NSPoint(x: leftX, y: upperBaseY))
    outline.line(to: NSPoint(x: hourglassCenterX, y: neckY))
    outline.line(to: NSPoint(x: leftX, y: lowerBaseY))

    outline.move(to: NSPoint(x: rightX, y: upperBaseY))
    outline.line(to: NSPoint(x: hourglassCenterX, y: neckY))
    outline.line(to: NSPoint(x: rightX, y: lowerBaseY))

    outlineColor.setStroke()
    outline.stroke()

    guard let level else { return }

    let remaining = CGFloat(level) / 100
    let consumed = 1 - remaining
    let sandColor = color.withAlphaComponent(0.82)

    let upperChamber = NSBezierPath()
    upperChamber.move(to: NSPoint(x: leftX + 0.8, y: upperBaseY - 0.4))
    upperChamber.line(to: NSPoint(x: rightX - 0.8, y: upperBaseY - 0.4))
    upperChamber.line(to: NSPoint(x: hourglassCenterX, y: neckY + 0.25))
    upperChamber.close()

    let upperHeight = upperBaseY - neckY - 0.65
    let upperFillHeight = upperHeight * sqrt(remaining)
    let upperFillRect = NSRect(
      x: leftX,
      y: neckY + 0.2,
      width: rightX - leftX,
      height: upperFillHeight
    )

    if upperFillHeight > 0 {
      NSGraphicsContext.current?.saveGraphicsState()
      upperChamber.addClip()
      sandColor.setFill()
      upperFillRect.fill()
      NSGraphicsContext.current?.restoreGraphicsState()
    }

    let lowerHeight = neckY - lowerBaseY
    let pileHeight = consumed > 0 ? max(1, lowerHeight * consumed) : 0
    let pileTopY = lowerBaseY + pileHeight

    if pileHeight > 0 {
      let lowerPile = NSBezierPath()
      lowerPile.move(to: NSPoint(x: leftX + 0.8, y: lowerBaseY + 0.35))
      lowerPile.line(to: NSPoint(x: rightX - 0.8, y: lowerBaseY + 0.35))
      lowerPile.line(to: NSPoint(x: hourglassCenterX, y: pileTopY))
      lowerPile.close()
      sandColor.setFill()
      lowerPile.fill()
    }

    if level > 0, level < 100 {
      let stream = NSBezierPath()
      stream.lineWidth = 0.65
      stream.lineCapStyle = .round
      stream.move(to: NSPoint(x: hourglassCenterX, y: neckY - 0.15))
      stream.line(to: NSPoint(x: hourglassCenterX, y: max(pileTopY, lowerBaseY + 0.8)))
      sandColor.setStroke()
      stream.stroke()
    }
  }

  private static func drawPercentage(_ value: String, color: NSColor) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .left
    drawText(
      value,
      in: percentageRect,
      font: NSFont.systemFont(ofSize: 9.4, weight: .semibold),
      paragraph: paragraph,
      color: color
    )
  }

  private static func drawText(
    _ value: String,
    in rect: NSRect,
    font: NSFont,
    paragraph: NSParagraphStyle,
    color: NSColor
  ) {
    (value as NSString).draw(
      in: rect,
      withAttributes: [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph,
      ]
    )
  }
}
