// Draws a simple 600x800 Moonlight cover: a TV outline with big text inside and a caption under it.
// usage: swift cover.swift <out.png> <big text> <caption> [accent hex, e.g. 3df273]
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let a = CommandLine.arguments
guard a.count >= 4 else { print("usage: cover <out.png> <big text> <caption> [accent hex]"); exit(2) }
var rgb: UInt32 = 0x3DF273
if a.count > 4 { Scanner(string: a[4]).scanHexInt32(&rgb) }
let accent = NSColor(srgbRed: CGFloat(rgb >> 16 & 255) / 255, green: CGFloat(rgb >> 8 & 255) / 255,
                     blue: CGFloat(rgb & 255) / 255, alpha: 1)
let W = 600, H = 800
let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)

// Background: dark blue at the top to near black at the bottom, with a soft glow of the accent colour.
let bg = CGGradient(colorsSpace: nil, colors: [CGColor(srgbRed: 0.09, green: 0.11, blue: 0.20, alpha: 1),
                                               CGColor(srgbRed: 0.02, green: 0.02, blue: 0.04, alpha: 1)] as CFArray,
                    locations: [0, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: 0), options: [])
let glow = CGGradient(colorsSpace: nil, colors: [accent.withAlphaComponent(0.28).cgColor, accent.withAlphaComponent(0).cgColor] as CFArray,
                      locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: 300, y: 470), startRadius: 0, endCenter: CGPoint(x: 300, y: 470), endRadius: 330, options: [])

// The TV: a rounded screen outline on a small stand.
let screen = CGRect(x: 70, y: 330, width: 460, height: 280)
ctx.addPath(CGPath(roundedRect: screen, cornerWidth: 26, cornerHeight: 26, transform: nil))
ctx.setFillColor(CGColor(gray: 0, alpha: 0.45)); ctx.fillPath()
ctx.addPath(CGPath(roundedRect: screen, cornerWidth: 26, cornerHeight: 26, transform: nil))
ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.92)); ctx.setLineWidth(10); ctx.strokePath()
ctx.setFillColor(CGColor(gray: 1, alpha: 0.92))
ctx.fill(CGRect(x: 285, y: 290, width: 30, height: 40))
ctx.addPath(CGPath(roundedRect: CGRect(x: 210, y: 278, width: 180, height: 16), cornerWidth: 8, cornerHeight: 8, transform: nil)); ctx.fillPath()

func draw(_ s: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, centerY: CGFloat, maxWidth: CGFloat) {
    var font = NSFont.systemFont(ofSize: size, weight: weight)
    var t = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: color, .kern: size * 0.03])
    if t.size().width > maxWidth {   // shrink long text to fit
        font = NSFont.systemFont(ofSize: size * maxWidth / t.size().width, weight: weight)
        t = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: color, .kern: font.pointSize * 0.03])
    }
    let ts = t.size()
    t.draw(at: CGPoint(x: (CGFloat(W) - ts.width) / 2, y: centerY - ts.height / 2))
}
draw(a[2], size: 170, weight: .black, color: accent, centerY: screen.midY, maxWidth: screen.width - 60)
draw(a[3].uppercased(), size: 64, weight: .heavy, color: .white, centerY: 175, maxWidth: 520)
NSGraphicsContext.current = nil

let dst = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dst, ctx.makeImage()!, nil)
exit(CGImageDestinationFinalize(dst) ? 0 : 1)
