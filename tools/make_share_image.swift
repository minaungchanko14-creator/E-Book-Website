// Draws public/og-image.jpg (1200x630 Facebook share preview) and
// public/apple-touch-icon.png (180x180) from the book covers in docs/assets.
// Run from the project folder:  swift tools/make_share_image.swift
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("docs/assets")
let out = root.appendingPathComponent("public")
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

func cover(_ prefix: String) -> NSImage {
    let name = try! FileManager.default.contentsOfDirectory(atPath: assets.path)
        .first { $0.hasPrefix(prefix) }!
    return NSImage(contentsOf: assets.appendingPathComponent(name))!
}

func render(width: Int, height: Int, draw: (CGContext) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw(NSGraphicsContext.current!.cgContext)
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let navy = NSColor(red: 0.027, green: 0.039, blue: 0.071, alpha: 1)
let blue = NSColor(red: 0.231, green: 0.510, blue: 0.965, alpha: 1)

// --- Share image -------------------------------------------------------------
let W = 1200, H = 630
let og = render(width: W, height: H) { ctx in
    navy.setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()
    // blue glow behind the covers
    let glow = NSGradient(colors: [blue.withAlphaComponent(0.45), navy.withAlphaComponent(0)])!
    glow.draw(fromCenter: NSPoint(x: 600, y: 250), radius: 0, toCenter: NSPoint(x: 600, y: 250), radius: 520, options: [])
    // faint grid
    NSColor(white: 1, alpha: 0.04).setStroke()
    for x in stride(from: 0, to: W, by: 56) { NSBezierPath.strokeLine(from: NSPoint(x: x, y: 0), to: NSPoint(x: x, y: H)) }
    for y in stride(from: 0, to: H, by: 56) { NSBezierPath.strokeLine(from: NSPoint(x: 0, y: y), to: NSPoint(x: W, y: y)) }

    // title
    let title = NSMutableAttributedString(string: "Ong Sike ", attributes: [
        .font: NSFont.systemFont(ofSize: 64, weight: .bold), .foregroundColor: NSColor.white])
    title.append(NSAttributedString(string: "Books", attributes: [
        .font: NSFont.systemFont(ofSize: 64, weight: .bold), .foregroundColor: NSColor(red: 0.376, green: 0.647, blue: 0.980, alpha: 1)]))
    let ts = title.size()
    title.draw(at: NSPoint(x: (CGFloat(W) - ts.width) / 2, y: 520))
    let sub = NSAttributedString(string: "မြန်မာ E-books  ·  AI Image Prompts  ·  Bundle RM 79", attributes: [
        .font: NSFont(name: "Myanmar Sangam MN", size: 28) ?? NSFont.systemFont(ofSize: 28),
        .foregroundColor: NSColor(white: 1, alpha: 0.75)])
    let ss = sub.size()
    sub.draw(at: NSPoint(x: (CGFloat(W) - ss.width) / 2, y: 470))

    // covers in a row, middle one largest
    let books = ["you-can-change", "you-can-do-it", "the-rich-don-t", "bitcoin-the-new", "digital-product"].map(cover)
    let heights: [CGFloat] = [270, 315, 360, 315, 270]
    let gap: CGFloat = 24
    let widths = zip(books, heights).map { $1 * $0.size.width / $0.size.height }
    var x = (CGFloat(W) - widths.reduce(0, +) - gap * CGFloat(books.count - 1)) / 2
    for (i, img) in books.enumerated() {
        let rect = NSRect(x: x, y: 60 + (360 - heights[i]) / 2, width: widths[i], height: heights[i])
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 30, color: NSColor.black.withAlphaComponent(0.6).cgColor)
        NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8).addClip()
        img.draw(in: rect)
        ctx.restoreGState()
        x += widths[i] + gap
    }
}
try! og.representation(using: .jpeg, properties: [.compressionFactor: 0.85])!
    .write(to: out.appendingPathComponent("og-image.jpg"))

// --- iPhone home-screen icon -------------------------------------------------
let icon = render(width: 180, height: 180) { _ in
    navy.setFill(); NSRect(x: 0, y: 0, width: 180, height: 180).fill()
    let grad = NSGradient(colors: [NSColor(red: 0.31, green: 0.56, blue: 0.97, alpha: 1), NSColor(red: 0.18, green: 0.44, blue: 0.91, alpha: 1)])!
    grad.draw(in: NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 180, height: 180), xRadius: 0, yRadius: 0), angle: -90)
    let t = NSAttributedString(string: "OS", attributes: [
        .font: NSFont.systemFont(ofSize: 84, weight: .heavy), .foregroundColor: NSColor.white])
    let s = t.size()
    t.draw(at: NSPoint(x: (180 - s.width) / 2, y: (180 - s.height) / 2))
}
try! icon.representation(using: .png, properties: [:])!.write(to: out.appendingPathComponent("apple-touch-icon.png"))
print("wrote public/og-image.jpg and public/apple-touch-icon.png")
