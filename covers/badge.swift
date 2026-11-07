// Adds a text badge (e.g. "HUD") to the top-right corner of a cover image for Moonlight.
// usage: swift badge.swift <in.png> <out.png> <text>
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let a = CommandLine.arguments
guard a.count == 4, let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, nil),
      let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { print("usage: badge <in.png> <out.png> <text>"); exit(2) }
let W = img.width, H = img.height
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                          space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(1) }
ctx.draw(img, in: CGRect(x: 0, y: 0, width: W, height: H))

NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
let scale = CGFloat(W) / 600                       // sized for a 600-pixel-wide cover
let font = NSFont.systemFont(ofSize: 92 * scale, weight: .black)
let text = NSAttributedString(string: a[3], attributes: [
    .font: font, .foregroundColor: NSColor(srgbRed: 0.24, green: 0.95, blue: 0.45, alpha: 1), .kern: 2 * scale])
let ts = text.size()
let padX = 26 * scale, padY = 8 * scale, margin = 26 * scale
let box = CGRect(x: CGFloat(W) - margin - ts.width - 2 * padX, y: CGFloat(H) - margin - ts.height - 2 * padY,
                 width: ts.width + 2 * padX, height: ts.height + 2 * padY)
let path = CGPath(roundedRect: box, cornerWidth: 22 * scale, cornerHeight: 22 * scale, transform: nil)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -6 * scale), blur: 18 * scale, color: CGColor(gray: 0, alpha: 0.6))
ctx.addPath(path); ctx.setFillColor(CGColor(gray: 0.05, alpha: 0.88)); ctx.fillPath()
ctx.restoreGState()
ctx.addPath(path); ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.9)); ctx.setLineWidth(5 * scale); ctx.strokePath()
text.draw(at: CGPoint(x: box.minX + padX, y: box.minY + padY))
NSGraphicsContext.current = nil

guard let out = ctx.makeImage(),
      let dst = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[2]) as CFURL, UTType.png.identifier as CFString, 1, nil) else { exit(1) }
CGImageDestinationAddImage(dst, out, nil)
exit(CGImageDestinationFinalize(dst) ? 0 : 1)
