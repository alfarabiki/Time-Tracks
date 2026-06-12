import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final src = img.decodeWebP(
    File('Rumah_Sakit_Radjak_Hospital_Salemba.webp').readAsBytesSync(),
  )!;
  final out = src.convert(numChannels: 4);
  for (final p in out) {
    if (p.r >= 238 && p.g >= 238 && p.b >= 238) {
      p.a = 0; // near-white -> transparent
    }
  }
  File('assets/branding/radjak_logo.png').writeAsBytesSync(img.encodePng(out));
  stdout.writeln('wrote assets/branding/radjak_logo.png ${out.width}x${out.height}');
}
