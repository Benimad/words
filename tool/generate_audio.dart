// Generates every sound effect shipped in `assets/audio/` as 16-bit PCM WAV.
//
// The game ships **synthesised** audio rather than third-party sound files so
// that the entire project is original and free of licensing questions. Run it
// with:
//
//     dart run tool/generate_audio.dart
//
// Re-running is idempotent: the same seeds produce byte-identical files.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int kSampleRate = 44100;

/// A single synthesiser voice: a frequency sweep shaped by an ADSR-ish envelope.
class Voice {
  Voice({
    required this.startFreq,
    double? endFreq,
    required this.start,
    required this.duration,
    this.gain = 0.35,
    this.wave = Wave.sine,
    this.attack = 0.01,
    this.decay = 0.9,
    this.vibrato = 0,
  }) : endFreq = endFreq ?? startFreq;

  final double startFreq;
  final double endFreq;

  /// Offset in seconds from the beginning of the clip.
  final double start;
  final double duration;
  final double gain;
  final Wave wave;

  /// Attack time in seconds.
  final double attack;

  /// Fraction of the remaining time spent decaying to silence (0..1).
  final double decay;

  /// Vibrato depth in Hz (0 disables).
  final double vibrato;
}

enum Wave { sine, triangle, square, noise }

/// Renders [voices] into a normalised mono buffer of [seconds] length.
Float64List render(double seconds, List<Voice> voices, {int seed = 7}) {
  final total = (seconds * kSampleRate).round();
  final buffer = Float64List(total);
  final rng = math.Random(seed);

  for (final v in voices) {
    final startSample = (v.start * kSampleRate).round();
    final lengthSamples = (v.duration * kSampleRate).round();
    // Phase is integrated so that frequency sweeps stay continuous (no clicks).
    var phase = 0.0;

    for (var i = 0; i < lengthSamples; i++) {
      final index = startSample + i;
      if (index < 0 || index >= total) continue;

      final t = i / lengthSamples; // normalised 0..1 progress through the voice
      final seconds = i / kSampleRate;

      // Exponential glide reads more musical than a linear ramp.
      final freq = v.startFreq * math.pow(v.endFreq / v.startFreq, t) +
          (v.vibrato == 0
              ? 0
              : v.vibrato * math.sin(2 * math.pi * 6.0 * seconds));

      phase += 2 * math.pi * freq / kSampleRate;

      final double sample;
      switch (v.wave) {
        case Wave.sine:
          sample = math.sin(phase);
        case Wave.triangle:
          final p = (phase / (2 * math.pi)) % 1.0;
          sample = 4 * (p < 0.5 ? p : 1 - p) - 1;
        case Wave.square:
          // Softened square: odd harmonics only, keeps it from sounding harsh.
          sample = 0.6 * math.sin(phase) + 0.2 * math.sin(3 * phase);
        case Wave.noise:
          sample = rng.nextDouble() * 2 - 1;
      }

      // Envelope: linear attack, exponential decay to zero at the tail.
      final attackSamples = math.max(1, (v.attack * kSampleRate).round());
      final env = i < attackSamples
          ? i / attackSamples
          : math.pow(1 - ((i - attackSamples) / (lengthSamples - attackSamples))
                  .clamp(0.0, 1.0), 1 / v.decay).toDouble();

      buffer[index] += sample * env * v.gain;
    }
  }

  // Normalise with headroom so nothing clips after mixing.
  var peak = 0.0;
  for (final s in buffer) {
    peak = math.max(peak, s.abs());
  }
  if (peak > 0) {
    final scale = 0.89 / peak;
    for (var i = 0; i < buffer.length; i++) {
      buffer[i] *= scale;
    }
  }
  return buffer;
}

/// Wraps a mono float buffer in a 16-bit PCM WAV container.
Uint8List toWav(Float64List samples) {
  const channels = 1;
  const bitsPerSample = 16;
  final dataBytes = samples.length * 2;
  final bytes = BytesBuilder();

  void writeString(String s) => bytes.add(s.codeUnits);
  void writeU32(int v) =>
      bytes.add(Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little));
  void writeU16(int v) =>
      bytes.add(Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little));

  writeString('RIFF');
  writeU32(36 + dataBytes);
  writeString('WAVE');
  writeString('fmt ');
  writeU32(16); // PCM chunk size
  writeU16(1); // format = PCM
  writeU16(channels);
  writeU32(kSampleRate);
  writeU32(kSampleRate * channels * bitsPerSample ~/ 8); // byte rate
  writeU16(channels * bitsPerSample ~/ 8); // block align
  writeU16(bitsPerSample);
  writeString('data');
  writeU32(dataBytes);

  final pcm = Uint8List(dataBytes);
  final view = pcm.buffer.asByteData();
  for (var i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    view.setInt16(i * 2, (clamped * 32767).round(), Endian.little);
  }
  bytes.add(pcm);
  return bytes.toBytes();
}

/// Musical helper: MIDI note number -> frequency in Hz.
double note(int midi) => 440 * math.pow(2, (midi - 69) / 12).toDouble();

void main() {
  final dir = Directory('assets/audio')..createSync(recursive: true);

  // Each entry: file name -> (clip length, voices).
  final clips = <String, ({double seconds, List<Voice> voices})>{
    // Soft tick as the finger passes over a new letter. Deliberately short and
    // quiet — it fires many times per swipe.
    'tap': (
      seconds: 0.09,
      voices: [
        Voice(
          startFreq: note(84),
          endFreq: note(86),
          start: 0,
          duration: 0.08,
          gain: 0.25,
          wave: Wave.triangle,
          attack: 0.004,
          decay: 0.5,
        ),
      ],
    ),
    // Rising two-note chime when a word is accepted.
    'word_found': (
      seconds: 0.5,
      voices: [
        Voice(startFreq: note(72), start: 0, duration: 0.18, wave: Wave.sine),
        Voice(startFreq: note(76), start: 0.08, duration: 0.20, wave: Wave.sine),
        Voice(startFreq: note(79), start: 0.16, duration: 0.30, wave: Wave.sine),
        Voice(
          startFreq: note(91),
          start: 0.16,
          duration: 0.26,
          gain: 0.12,
          wave: Wave.triangle,
        ),
      ],
    ),
    // Gentle descending "nope" — never harsh, this is a relaxing game.
    'invalid': (
      seconds: 0.24,
      voices: [
        Voice(
          startFreq: note(57),
          endFreq: note(53),
          start: 0,
          duration: 0.2,
          gain: 0.22,
          wave: Wave.triangle,
          attack: 0.008,
          decay: 0.7,
        ),
      ],
    ),
    // Major arpeggio fanfare for finishing a level.
    'level_complete': (
      seconds: 1.5,
      voices: [
        Voice(startFreq: note(72), start: 0.00, duration: 0.22),
        Voice(startFreq: note(76), start: 0.11, duration: 0.22),
        Voice(startFreq: note(79), start: 0.22, duration: 0.22),
        Voice(startFreq: note(84), start: 0.33, duration: 0.85, vibrato: 2.5),
        Voice(
          startFreq: note(88),
          start: 0.33,
          duration: 0.85,
          gain: 0.18,
          wave: Wave.triangle,
        ),
        Voice(
          startFreq: note(60),
          start: 0.33,
          duration: 0.9,
          gain: 0.16,
          wave: Wave.sine,
        ),
        // Airy shimmer tail.
        Voice(
          startFreq: 6000,
          endFreq: 11000,
          start: 0.30,
          duration: 0.5,
          gain: 0.05,
          wave: Wave.noise,
          attack: 0.05,
          decay: 0.4,
        ),
      ],
    ),
    // Bright metallic ping for collecting coins.
    'coin': (
      seconds: 0.35,
      voices: [
        Voice(
          startFreq: note(88),
          start: 0,
          duration: 0.07,
          gain: 0.3,
          wave: Wave.triangle,
          attack: 0.003,
        ),
        Voice(
          startFreq: note(95),
          start: 0.05,
          duration: 0.25,
          gain: 0.26,
          wave: Wave.triangle,
          attack: 0.003,
          decay: 0.55,
        ),
      ],
    ),
    // Soft UI click for buttons and navigation.
    'button': (
      seconds: 0.08,
      voices: [
        Voice(
          startFreq: note(76),
          endFreq: note(72),
          start: 0,
          duration: 0.07,
          gain: 0.22,
          wave: Wave.sine,
          attack: 0.003,
          decay: 0.45,
        ),
      ],
    ),
    // Magical sparkle when a hint is spent.
    'hint': (
      seconds: 0.6,
      voices: [
        Voice(
          startFreq: note(79),
          endFreq: note(91),
          start: 0,
          duration: 0.35,
          gain: 0.22,
          wave: Wave.sine,
          attack: 0.01,
          decay: 0.6,
        ),
        Voice(
          startFreq: note(86),
          endFreq: note(98),
          start: 0.1,
          duration: 0.4,
          gain: 0.14,
          wave: Wave.triangle,
          attack: 0.02,
          decay: 0.5,
        ),
      ],
    ),
    // Warm swell for unlocking a new world / milestone.
    'unlock': (
      seconds: 1.2,
      voices: [
        Voice(
          startFreq: note(60),
          endFreq: note(72),
          start: 0,
          duration: 0.6,
          gain: 0.24,
          wave: Wave.sine,
          attack: 0.08,
          decay: 0.8,
        ),
        Voice(startFreq: note(79), start: 0.35, duration: 0.5, gain: 0.2),
        Voice(startFreq: note(84), start: 0.45, duration: 0.6, gain: 0.2),
        Voice(startFreq: note(91), start: 0.55, duration: 0.6, gain: 0.12),
      ],
    ),
    // Streak / daily reward stinger.
    'streak': (
      seconds: 0.9,
      voices: [
        Voice(startFreq: note(69), start: 0.00, duration: 0.16, gain: 0.26),
        Voice(startFreq: note(74), start: 0.12, duration: 0.16, gain: 0.26),
        Voice(startFreq: note(81), start: 0.24, duration: 0.55, gain: 0.28,
            vibrato: 3),
        Voice(
          startFreq: 5000,
          endFreq: 9000,
          start: 0.22,
          duration: 0.35,
          gain: 0.05,
          wave: Wave.noise,
          attack: 0.03,
          decay: 0.35,
        ),
      ],
    ),
  };

  clips.forEach((name, clip) {
    final wav = toWav(render(clip.seconds, clip.voices));
    File('${dir.path}/$name.wav').writeAsBytesSync(wav);
    stdout.writeln('wrote $name.wav (${(wav.length / 1024).toStringAsFixed(1)} KB)');
  });

  stdout.writeln('\nDone — ${clips.length} sound effects generated.');
}
