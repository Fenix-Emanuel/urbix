// Arma un reel vertical 1080×1920 a partir de las escenas y transiciones del recorrido, con textos en pantalla.
// Uso: swift reel.swift <urbix|ignis> <carpeta gen> <salida.mp4>
import AVFoundation
import CoreGraphics
import CoreText
import ImageIO
import AppKit

let A = CommandLine.arguments
let variant = A[1], gen = A[2], outPath = A[3]
let W = 1080, H = 1920, FPS: Int32 = 30
let volt = CGColor(red: 0.36, green: 0.90, blue: 0.545, alpha: 1)
let white = CGColor(red: 0.93, green: 0.95, blue: 0.93, alpha: 1)

// ---------- Guion ----------
struct Txt { let label: String; let big: String }
enum Seg { case hold(String, Double, Txt?), clip(String, Double, Txt?), end([String]) }

let urbix: [Seg] = [
  .hold("m1.png", 2.6, Txt(label: "URBIX · MOVILIDAD ELÉCTRICA", big: "Monopatines, bicis y motos eléctricas")),
  .clip("u1.mp4", 1.5, nil),
  .hold("m2.png", 1.2, nil),
  .clip("u2.mp4", 1.5, nil),
  .hold("m3.png", 2.4, Txt(label: "10 MODELOS", big: "23% off pagando por transferencia")),
  .clip("u3.mp4", 1.5, nil),
  .hold("m4.png", 2.4, Txt(label: "ENVÍO GRATIS", big: "A todo el país, sale en el día")),
  .end(["URBIX", "Comprá online", "LINK EN BIO"])
]
let ignis: [Seg] = [
  .hold("m1.png", 2.6, Txt(label: "IGNIS STUDIO · CASO URBIX", big: "Una web que se siente como un comercial")),
  .clip("u1.mp4", 1.5, nil),
  .hold("m2.png", 1.2, nil),
  .clip("u2.mp4", 1.5, nil),
  .hold("m3.png", 2.4, Txt(label: "4 ESCENAS · 1 SOLA TOMA", big: "Todo el recorrido avanza con tu scroll")),
  .clip("u3.mp4", 1.5, nil),
  .hold("m4.png", 2.4, Txt(label: "+ TIENDA ONLINE", big: "Catálogo y pedidos directo a WhatsApp")),
  .end(["IGNIS STUDIO", "Webs cinematográficas", "¿QUERÉS UNA ASÍ? ESCRIBINOS"])
]
let script = variant == "ignis" ? ignis : urbix

// ---------- Utilidades de dibujo ----------
func loadCG(_ p: String) -> CGImage {
  let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: p) as CFURL, nil)!
  return CGImageSourceCreateImageAtIndex(src, 0, nil)!
}
func drawCover(_ ctx: CGContext, _ img: CGImage, zoom: CGFloat) {
  let iw = CGFloat(img.width), ih = CGFloat(img.height)
  let r = max(CGFloat(W) / iw, CGFloat(H) / ih) * zoom
  let dw = iw * r, dh = ih * r
  ctx.interpolationQuality = .high
  ctx.draw(img, in: CGRect(x: (CGFloat(W) - dw) / 2, y: (CGFloat(H) - dh) / 2, width: dw, height: dh))
}
func font(_ name: String, _ size: CGFloat) -> CTFont { CTFontCreateWithName(name as CFString, size, nil) }
// Texto centrado con ajuste de líneas; y = línea base de la primera línea (desde abajo)
func drawText(_ ctx: CGContext, _ s: String, _ f: CTFont, _ color: CGColor, centerY: CGFloat, maxW: CGFloat, alpha: CGFloat, kern: CGFloat = 0) -> CGFloat {
  let attrs: [NSAttributedString.Key: Any] = [.init(kCTFontAttributeName as String): f,
    .init(kCTForegroundColorAttributeName as String): color.copy(alpha: alpha)!, .init(kCTKernAttributeName as String): kern]
  let astr = NSAttributedString(string: s, attributes: attrs)
  let fs = CTFramesetterCreateWithAttributedString(astr)
  let size = CTFramesetterSuggestFrameSizeWithConstraints(fs, CFRange(location: 0, length: 0), nil, CGSize(width: maxW, height: 2000), nil)
  // centrar cada línea
  let path = CGPath(rect: CGRect(x: (CGFloat(W) - maxW) / 2, y: centerY - size.height / 2, width: maxW, height: size.height + 2), transform: nil)
  let para = NSMutableAttributedString(attributedString: astr)
  let style = NSMutableParagraphStyle(); style.alignment = .center
  para.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: para.length))
  let fs2 = CTFramesetterCreateWithAttributedString(para)
  CTFrameDraw(CTFramesetterCreateFrame(fs2, CFRange(location: 0, length: 0), path, nil), ctx)
  return size.height
}
func overlay(_ ctx: CGContext, _ t: Txt, _ local: Double) {
  let a = CGFloat(min(1, local / 0.35))                       // entrada suave
  let rise = (1 - a) * 24
  // degradado oscuro abajo para legibilidad
  let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [CGColor(gray: 0, alpha: 0), CGColor(gray: 0, alpha: 0.78 * a)] as CFArray, locations: [0, 1])!
  ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: 1000), end: CGPoint(x: 0, y: 0), options: [])
  let bigH = drawText(ctx, t.big, font("AvenirNextCondensed-Heavy", 92), white, centerY: 600 - rise, maxW: 900, alpha: a)
  _ = drawText(ctx, t.label, font("Menlo-Bold", 30), volt, centerY: 600 + bigH / 2 + 46 - rise, maxW: 940, alpha: a, kern: 4)
}
func endCard(_ ctx: CGContext, _ lines: [String], _ local: Double) {
  ctx.setFillColor(CGColor(red: 0.027, green: 0.035, blue: 0.04, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
  let glow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [volt.copy(alpha: 0.28)!, volt.copy(alpha: 0)!] as CFArray, locations: [0, 1])!
  ctx.drawRadialGradient(glow, startCenter: CGPoint(x: W / 2, y: H / 2), startRadius: 0, endCenter: CGPoint(x: W / 2, y: H / 2), endRadius: 760, options: [])
  let a = CGFloat(min(1, local / 0.4)), s = 0.94 + 0.06 * a
  ctx.saveGState(); ctx.translateBy(x: CGFloat(W) / 2, y: CGFloat(H) / 2); ctx.scaleBy(x: s, y: s); ctx.translateBy(x: -CGFloat(W) / 2, y: -CGFloat(H) / 2)
  let titleSize: CGFloat = lines[0].count > 6 ? 128 : 220
  _ = drawText(ctx, lines[0], font("AvenirNextCondensed-Heavy", titleSize), volt, centerY: 1010, maxW: 1000, alpha: a, kern: 2)
  _ = drawText(ctx, lines[1], font("AvenirNext-DemiBold", 58), white, centerY: 840, maxW: 960, alpha: a)
  _ = drawText(ctx, lines[2], font("Menlo-Bold", 30), volt, centerY: 720, maxW: 960, alpha: a, kern: 4)
  ctx.restoreGState()
}

// ---------- Escritor de video ----------
let outURL = URL(fileURLWithPath: outPath)
try? FileManager.default.removeItem(at: outURL)
let writer = try! AVAssetWriter(outputURL: outURL, fileType: .mp4)
let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
  AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: W, AVVideoHeightKey: H,
  AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 14_000_000, AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel]])
input.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
  kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB, kCVPixelBufferWidthKey as String: W, kCVPixelBufferHeightKey as String: H])
writer.add(input); writer.startWriting(); writer.startSession(atSourceTime: .zero)

var frameNo: Int64 = 0
func emit(_ paint: (CGContext) -> Void) {
  var pb: CVPixelBuffer?
  CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pb)
  let buf = pb!
  CVPixelBufferLockBaseAddress(buf, [])
  let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buf), width: W, height: H, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buf),
                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)!
  paint(ctx)
  CVPixelBufferUnlockBaseAddress(buf, [])
  while !input.isReadyForMoreMediaData { usleep(2000) }
  adaptor.append(buf, withPresentationTime: CMTime(value: frameNo, timescale: FPS))
  frameNo += 1
}

for seg in script {
  switch seg {
  case let .hold(file, secs, txt):
    let img = loadCG("\(gen)/\(file)")
    let n = Int(secs * Double(FPS))
    for i in 0..<n {
      let p = Double(i) / Double(n)
      emit { ctx in
        drawCover(ctx, img, zoom: 1 + CGFloat(p) * 0.05)
        if let t = txt { overlay(ctx, t, Double(i) / Double(FPS)) }
      }
    }
  case let .clip(file, speed, txt):
    let asset = AVURLAsset(url: URL(fileURLWithPath: "\(gen)/\(file)"))
    let g = AVAssetImageGenerator(asset: asset)
    g.appliesPreferredTrackTransform = true
    g.requestedTimeToleranceBefore = .zero; g.requestedTimeToleranceAfter = .zero
    let dur = CMTimeGetSeconds(asset.duration) - 0.05
    let n = Int(dur / speed * Double(FPS))
    for i in 0..<n {
      let t = min(dur, Double(i) * speed / Double(FPS))
      guard let img = try? g.copyCGImage(at: CMTime(seconds: t, preferredTimescale: 600), actualTime: nil) else { continue }
      emit { ctx in
        drawCover(ctx, img, zoom: 1)
        if let tx = txt { overlay(ctx, tx, Double(i) / Double(FPS)) }
      }
    }
  case let .end(lines):
    let n = Int(2.6 * Double(FPS))
    for i in 0..<n { emit { ctx in endCard(ctx, lines, Double(i) / Double(FPS)) } }
  }
}

input.markAsFinished()
let sem = DispatchSemaphore(value: 0)
writer.finishWriting { sem.signal() }
sem.wait()
print("ok \(variant): \(frameNo) cuadros, \(String(format: "%.1f", Double(frameNo) / Double(FPS))) s → \(outPath)")
