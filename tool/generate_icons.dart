// Renders the WordQuest launcher icon to PNG at every Android density.
//
// The mark matches `QuestLogo` in the app: a compass rose built from four
// letter tiles around a central gem, on a violet gradient. Drawing it here with
// a tiny software rasteriser (rather than exporting from a design tool) keeps
// the icon reproducible from source and free of third-party assets.
//
//     dart run tool/generate_icons.dart
//
// Legacy (pre-API 26) launchers use these PNGs. API 26+ uses the adaptive icon
// in `res/mipmap-anydpi-v26/ic_launcher.xml`, whose layers are vector drawables.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// 4x supersampling — cheap here, and it removes all the jaggies.
const int kSupersample = 4;

class Rgba {
  const Rgba(this.r, this.g, this.b, [this.a = 255]);
  final int r, g, b, a;

  static Rgba lerp(Rgba a, Rgba b, double t) => Rgba(
        (a.r + (b.r - a.r) * t).round(),
        (a.g + (b.g - a.g) * t).round(),
        (a.b + (b.b - a.b) * t).round(),
        (a.a + (b.a - a.a) * t).round(),
      );
}

// Brand palette, mirroring lib/core/theme/app_palette.dart.
const violetLight = Rgba(0x9B, 0x85, 0xFF);
const violet = Rgba(0x6C, 0x4C, 0xF1);
const violetDark = Rgba(0x4A, 0x2F, 0xC7);
const teal = Rgba(0x21, 0xC7, 0xBE);
const amber = Rgba(0xFF, 0xB0, 0x20);
const rose = Rgba(0xF4, 0x72, 0xB6);
const sky = Rgba(0x38, 0xBD, 0xF8);
const white = Rgba(0xFF, 0xFF, 0xFF);

/// A simple RGBA canvas with alpha compositing.
class Bitmap {
  Bitmap(this.width, this.height)
      : pixels = Uint8List(width * height * 4);

  final int width;
  final int height;
  final Uint8List pixels;

  void blend(int x, int y, Rgba color) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    final i = (y * width + x) * 4;
    final srcA = color.a / 255;
    final dstA = pixels[i + 3] / 255;
    final outA = srcA + dstA * (1 - srcA);
    if (outA == 0) return;

    pixels[i] = ((color.r * srcA + pixels[i] * dstA * (1 - srcA)) / outA).round();
    pixels[i + 1] =
        ((color.g * srcA + pixels[i + 1] * dstA * (1 - srcA)) / outA).round();
    pixels[i + 2] =
        ((color.b * srcA + pixels[i + 2] * dstA * (1 - srcA)) / outA).round();
    pixels[i + 3] = (outA * 255).round();
  }

  /// Box-downsamples this bitmap by [factor] — the anti-aliasing step.
  Bitmap downsample(int factor) {
    final out = Bitmap(width ~/ factor, height ~/ factor);
    final samples = factor * factor;

    for (var y = 0; y < out.height; y++) {
      for (var x = 0; x < out.width; x++) {
        var r = 0, g = 0, b = 0, a = 0;
        for (var dy = 0; dy < factor; dy++) {
          for (var dx = 0; dx < factor; dx++) {
            final i = ((y * factor + dy) * width + (x * factor + dx)) * 4;
            r += pixels[i];
            g += pixels[i + 1];
            b += pixels[i + 2];
            a += pixels[i + 3];
          }
        }
        final o = (y * out.width + x) * 4;
        out.pixels[o] = r ~/ samples;
        out.pixels[o + 1] = g ~/ samples;
        out.pixels[o + 2] = b ~/ samples;
        out.pixels[o + 3] = a ~/ samples;
      }
    }
    return out;
  }
}

/// Signed-distance helper: is (px,py) inside a rounded rectangle?
bool insideRoundedRect(
  double px,
  double py,
  double cx,
  double cy,
  double halfW,
  double halfH,
  double radius,
) {
  final dx = (px - cx).abs() - (halfW - radius);
  final dy = (py - cy).abs() - (halfH - radius);
  if (dx <= 0 && dy <= 0) return true;
  final ox = math.max(dx, 0.0);
  final oy = math.max(dy, 0.0);
  return math.sqrt(ox * ox + oy * oy) <= radius;
}

/// Draws the mark into a supersampled bitmap of side [size].
Bitmap renderIcon(int size, {required bool withBackground}) {
  final s = size * kSupersample;
  final bitmap = Bitmap(s, s);
  final centre = s / 2;

  // --- Background: rounded square with a diagonal violet gradient ----------
  if (withBackground) {
    final radius = s * 0.22;
    for (var y = 0; y < s; y++) {
      for (var x = 0; x < s; x++) {
        if (!insideRoundedRect(
          x.toDouble(),
          y.toDouble(),
          centre,
          centre,
          centre,
          centre,
          radius,
        )) {
          continue;
        }
        // Diagonal ramp: light top-left, dark bottom-right.
        final t = ((x + y) / (2 * s)).clamp(0.0, 1.0);
        final color = t < 0.5
            ? Rgba.lerp(violetLight, violet, t * 2)
            : Rgba.lerp(violet, violetDark, (t - 0.5) * 2);
        bitmap.blend(x, y, color);
      }
    }
  }

  // --- Sweeping ring ------------------------------------------------------
  final ringRadius = s * 0.34;
  final ringWidth = s * 0.035;
  for (var y = 0; y < s; y++) {
    for (var x = 0; x < s; x++) {
      final dx = x - centre;
      final dy = y - centre;
      final distance = math.sqrt(dx * dx + dy * dy);
      if ((distance - ringRadius).abs() > ringWidth) continue;

      // Colour cycles around the ring, matching the in-app sweep gradient.
      var angle = math.atan2(dy, dx) + math.pi / 2;
      if (angle < 0) angle += 2 * math.pi;
      final t = (angle / (2 * math.pi)) % 1.0;

      final Rgba color;
      if (t < 0.33) {
        color = Rgba.lerp(violetLight, teal, t / 0.33);
      } else if (t < 0.66) {
        color = Rgba.lerp(teal, amber, (t - 0.33) / 0.33);
      } else {
        color = Rgba.lerp(amber, violetLight, (t - 0.66) / 0.34);
      }
      bitmap.blend(x, y, Rgba(color.r, color.g, color.b, 235));
    }
  }

  // --- Four compass tiles (diamonds) --------------------------------------
  // Deliberately excludes violet: a violet tile disappears against the
  // violet background.
  const tileColors = [sky, teal, amber, rose];
  final tileDistance = s * 0.205;
  final tileHalf = s * 0.068;

  for (var i = 0; i < 4; i++) {
    final angle = -math.pi / 2 + i * math.pi / 2;
    final tcx = centre + math.cos(angle) * tileDistance;
    final tcy = centre + math.sin(angle) * tileDistance;
    final base = tileColors[i];

    for (var y = 0; y < s; y++) {
      for (var x = 0; x < s; x++) {
        // Rotate the sample point 45° into the tile's own space.
        final dx = x - tcx;
        final dy = y - tcy;
        const cos45 = 0.7071067811865476;
        final rx = dx * cos45 + dy * cos45;
        final ry = -dx * cos45 + dy * cos45;

        if (!insideRoundedRect(
          rx,
          ry,
          0,
          0,
          tileHalf,
          tileHalf,
          tileHalf * 0.3,
        )) {
          continue;
        }

        // Shade each tile top-left to bottom-right for a little depth.
        final t = ((rx + ry) / (4 * tileHalf) + 0.5).clamp(0.0, 1.0);
        bitmap.blend(
          x,
          y,
          Rgba.lerp(
            Rgba.lerp(base, white, 0.15),
            Rgba(
              (base.r * 0.65).round(),
              (base.g * 0.65).round(),
              (base.b * 0.65).round(),
            ),
            t,
          ),
        );
      }
    }
  }

  // --- Centre gem ---------------------------------------------------------
  final gemRadius = s * 0.09;
  for (var y = 0; y < s; y++) {
    for (var x = 0; x < s; x++) {
      final dx = x - centre;
      final dy = y - centre;
      if (math.sqrt(dx * dx + dy * dy) > gemRadius) continue;
      final t = ((dx + dy) / (2 * gemRadius) + 0.5).clamp(0.0, 1.0);
      bitmap.blend(x, y, Rgba.lerp(white, violetLight, t));
    }
  }

  return bitmap.downsample(kSupersample);
}

// ===== Minimal PNG encoder ================================================

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc ^= byte;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}

Uint8List _chunk(String type, List<int> data) {
  final out = BytesBuilder();
  final typeAndData = <int>[...ascii.encode(type), ...data];
  out.add(Uint8List(4)..buffer.asByteData().setUint32(0, data.length));
  out.add(typeAndData);
  out.add(Uint8List(4)..buffer.asByteData().setUint32(0, _crc32(typeAndData)));
  return out.toBytes();
}

Uint8List encodePng(Bitmap bitmap) {
  // Raw scanlines, each prefixed with filter type 0 (None).
  final raw = BytesBuilder();
  for (var y = 0; y < bitmap.height; y++) {
    raw.addByte(0);
    raw.add(
      bitmap.pixels.sublist(
        y * bitmap.width * 4,
        (y + 1) * bitmap.width * 4,
      ),
    );
  }

  final header = Uint8List(13);
  final headerView = header.buffer.asByteData();
  headerView.setUint32(0, bitmap.width);
  headerView.setUint32(4, bitmap.height);
  header[8] = 8; // bit depth
  header[9] = 6; // colour type: RGBA
  header[10] = 0; // deflate
  header[11] = 0; // adaptive filtering
  header[12] = 0; // no interlace

  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
    ..._chunk('IHDR', header),
    ..._chunk('IDAT', ZLibEncoder().convert(raw.toBytes())),
    ..._chunk('IEND', const []),
  ]);
}

void main() {
  // Android launcher icon sizes per density bucket.
  const densities = <String, int>{
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };

  densities.forEach((density, size) {
    final dir = Directory('android/app/src/main/res/mipmap-$density')
      ..createSync(recursive: true);

    File('${dir.path}/ic_launcher.png')
        .writeAsBytesSync(encodePng(renderIcon(size, withBackground: true)));

    stdout.writeln('wrote mipmap-$density/ic_launcher.png (${size}px)');
  });

  // Play Store listing icon.
  Directory('store').createSync(recursive: true);
  File('store/play_store_icon_512.png')
      .writeAsBytesSync(encodePng(renderIcon(512, withBackground: true)));
  stdout.writeln('wrote store/play_store_icon_512.png (512px)');

  stdout.writeln('\nDone.');
}
