// Convierte un video en láminas JPEG de cuadros (grilla cols × rows) para dibujar en <canvas>.
// Uso: swift frames.swift <video.mp4> <carpeta_salida> <fps> <ancho_cuadro> <cols> <rows> <calidad 0-1>
import AVFoundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let a = CommandLine.arguments
guard a.count == 8 else { print("uso: video out fps ancho cols rows calidad"); exit(1) }
let url = URL(fileURLWithPath: a[1]), out = URL(fileURLWithPath: a[2])
let fps = Double(a[3])!, w = Int(a[4])!, cols = Int(a[5])!, rows = Int(a[6])!, q = Double(a[7])!
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

let asset = AVURLAsset(url: url)
let dur = CMTimeGetSeconds(asset.duration)
let track = asset.tracks(withMediaType: .video)[0]
let nat = track.naturalSize.applying(track.preferredTransform)
let h = Int((Double(w) * Double(abs(nat.height)) / Double(abs(nat.width))).rounded() / 2) * 2

let gen = AVAssetImageGenerator(asset: asset)
gen.appliesPreferredTrackTransform = true
gen.requestedTimeToleranceBefore = .zero
gen.requestedTimeToleranceAfter = .zero
gen.maximumSize = CGSize(width: w, height: h)

let count = Int(floor(dur * fps))
let per = cols * rows
var sheet = 0
var i = 0
while i < count {
  let ctx = CGContext(data: nil, width: w * cols, height: h * rows, bitsPerComponent: 8, bytesPerRow: 0,
                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
  for c in 0..<per where i + c < count {
    let t = CMTime(seconds: min(Double(i + c) / fps, dur - 0.02), preferredTimescale: 600)
    if let img = try? gen.copyCGImage(at: t, actualTime: nil) {
      let col = c % cols, row = c / cols
      ctx.draw(img, in: CGRect(x: col * w, y: (rows - 1 - row) * h, width: w, height: h))
    }
  }
  let dest = out.appendingPathComponent(String(format: "s%03d.jpg", sheet))
  let d = CGImageDestinationCreateWithURL(dest as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
  CGImageDestinationAddImage(d, ctx.makeImage()!, [kCGImageDestinationLossyCompressionQuality: q] as CFDictionary)
  CGImageDestinationFinalize(d)
  sheet += 1; i += per
}
print("{\"frames\":\(count),\"sheets\":\(sheet),\"w\":\(w),\"h\":\(h),\"cols\":\(cols),\"rows\":\(rows)}")
