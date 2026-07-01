import 'dart:typed_data';

/// Reads audio duration in whole seconds from raw file bytes.
int? parseAudioDurationFromBytes(List<int> bytes, [String? filename]) {
  if (bytes.isEmpty) return null;
  final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

  final lower = filename?.toLowerCase();
  if (lower != null) {
    if (lower.endsWith('.wav')) return _parseWavDuration(data);
    if (lower.endsWith('.mp3')) return _parseMp3Duration(data);
  }

  if (data.length >= 12) {
    final riff = String.fromCharCodes(data.sublist(0, 4));
    if (riff == 'RIFF') {
      final wave = String.fromCharCodes(data.sublist(8, 12));
      if (wave == 'WAVE') return _parseWavDuration(data);
    }
    if (data[0] == 0xFF && (data[1] & 0xE0) == 0xE0) {
      return _parseMp3Duration(data);
    }
    if (String.fromCharCodes(data.sublist(4, 8)) == 'ftyp') {
      return _parseMp4Duration(data);
    }
  }

  return _parseMp3Duration(data) ?? _parseWavDuration(data);
}

int _readU32LE(Uint8List data, int offset) {
  return data[offset] |
      (data[offset + 1] << 8) |
      (data[offset + 2] << 16) |
      (data[offset + 3] << 24);
}

int _readU32BE(Uint8List data, int offset) {
  return (data[offset] << 24) |
      (data[offset + 1] << 16) |
      (data[offset + 2] << 8) |
      data[offset + 3];
}

int? _parseWavDuration(Uint8List data) {
  if (data.length < 44) return null;
  if (String.fromCharCodes(data.sublist(0, 4)) != 'RIFF') return null;
  if (String.fromCharCodes(data.sublist(8, 12)) != 'WAVE') return null;

  var offset = 12;
  int? byteRate;
  int? dataSize;

  while (offset + 8 <= data.length) {
    final chunkId = String.fromCharCodes(data.sublist(offset, offset + 4));
    final chunkSize = _readU32LE(data, offset + 4);
    final chunkDataStart = offset + 8;
    if (chunkDataStart + chunkSize > data.length) break;

    if (chunkId == 'fmt ' && chunkDataStart + 8 <= data.length) {
      byteRate = _readU32LE(data, chunkDataStart + 8);
    } else if (chunkId == 'data') {
      dataSize = chunkSize;
    }

    offset = chunkDataStart + chunkSize + (chunkSize.isOdd ? 1 : 0);
  }

  if (byteRate != null && byteRate > 0 && dataSize != null && dataSize > 0) {
    return (dataSize / byteRate).ceil();
  }
  return null;
}

const _mpeg1Layer3Bitrates = [
  0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320,
];

const _mpeg2Layer3Bitrates = [
  0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160,
];

const _mpeg1SampleRates = [44100, 48000, 32000];
const _mpeg2SampleRates = [22050, 24000, 16000];
const _mpeg25SampleRates = [11025, 12000, 8000];

class _Mp3FrameInfo {
  const _Mp3FrameInfo({
    required this.offset,
    required this.bitrateBps,
    required this.sampleRate,
    required this.isMpeg1,
    required this.isMono,
    required this.frameSize,
  });

  final int offset;
  final int bitrateBps;
  final int sampleRate;
  final bool isMpeg1;
  final bool isMono;
  final int frameSize;
}

int _skipId3v2(Uint8List data) {
  if (data.length < 10) return 0;
  if (String.fromCharCodes(data.sublist(0, 3)) != 'ID3') return 0;
  final size = ((data[6] & 0x7F) << 21) |
      ((data[7] & 0x7F) << 14) |
      ((data[8] & 0x7F) << 7) |
      (data[9] & 0x7F);
  return 10 + size;
}

_Mp3FrameInfo? _parseMp3FrameHeader(Uint8List data, int index) {
  if (index + 4 > data.length) return null;
  if (data[index] != 0xFF || (data[index + 1] & 0xE0) != 0xE0) return null;

  final b1 = data[index + 1];
  final b2 = data[index + 2];
  final b3 = data[index + 3];

  final versionBits = (b1 >> 3) & 0x03;
  if (versionBits == 1) return null;

  final layer = (b1 >> 1) & 0x03;
  if (layer != 1) return null;

  final bitrateIndex = (b2 >> 4) & 0x0F;
  if (bitrateIndex == 0 || bitrateIndex == 0x0F) return null;

  final sampleRateIndex = (b2 >> 2) & 0x03;
  if (sampleRateIndex == 3) return null;

  final padding = (b2 >> 1) & 0x01;
  final isMono = ((b3 >> 6) & 0x03) == 3;

  final isMpeg1 = versionBits == 3;
  final bitrates = isMpeg1 ? _mpeg1Layer3Bitrates : _mpeg2Layer3Bitrates;
  final sampleRates = switch (versionBits) {
    3 => _mpeg1SampleRates,
    2 => _mpeg2SampleRates,
    0 => _mpeg25SampleRates,
    _ => _mpeg2SampleRates,
  };

  final bitrateKbps = bitrates[bitrateIndex];
  final sampleRate = sampleRates[sampleRateIndex];
  if (bitrateKbps <= 0 || sampleRate <= 0) return null;

  final bitrateBps = bitrateKbps * 1000;
  final frameSize = isMpeg1
      ? ((144 * bitrateBps) ~/ sampleRate) + padding
      : ((72 * bitrateBps) ~/ sampleRate) + padding;
  if (frameSize <= 0) return null;

  return _Mp3FrameInfo(
    offset: index,
    bitrateBps: bitrateBps,
    sampleRate: sampleRate,
    isMpeg1: isMpeg1,
    isMono: isMono,
    frameSize: frameSize,
  );
}

_Mp3FrameInfo? _findFirstMp3Frame(Uint8List data, int start) {
  final limit = data.length - 4;
  for (var i = start; i < limit; i++) {
    final frame = _parseMp3FrameHeader(data, i);
    if (frame != null) return frame;
  }
  return null;
}

int? _tryParseXingDuration(Uint8List data, _Mp3FrameInfo frame) {
  final sideInfoLength = frame.isMpeg1
      ? (frame.isMono ? 17 : 32)
      : (frame.isMono ? 9 : 17);
  final xingOffset = frame.offset + 4 + sideInfoLength;
  if (xingOffset + 12 > data.length) return null;

  final tag = String.fromCharCodes(data.sublist(xingOffset, xingOffset + 4));
  if (tag != 'Xing' && tag != 'Info') return null;

  final flags = _readU32BE(data, xingOffset + 4);
  var pos = xingOffset + 8;
  if ((flags & 0x01) != 0) {
    if (pos + 4 > data.length) return null;
    final frames = _readU32BE(data, pos);
    final samplesPerFrame = frame.isMpeg1 ? 1152 : 576;
    if (frames > 0 && frame.sampleRate > 0) {
      return ((frames * samplesPerFrame) / frame.sampleRate).ceil();
    }
  }
  return null;
}

int? _parseMp3Duration(Uint8List data) {
  final start = _skipId3v2(data);
  final frame = _findFirstMp3Frame(data, start);
  if (frame == null) return null;

  final xingDuration = _tryParseXingDuration(data, frame);
  if (xingDuration != null && xingDuration > 0) return xingDuration;

  final audioBytes = data.length - frame.offset;
  if (frame.bitrateBps <= 0) return null;
  final seconds = (audioBytes * 8) / frame.bitrateBps;
  return seconds.isFinite && seconds > 0 ? seconds.ceil() : null;
}

int? _parseMp4Duration(Uint8List data) {
  // Best-effort: read mvhd movie duration when present in uploaded m4a/aac.
  final mvhd = _findAscii(data, 'mvhd');
  if (mvhd == null || mvhd + 24 > data.length) return null;

  final version = data[mvhd + 8];
  if (version == 0) {
    if (mvhd + 24 > data.length) return null;
    final timescale = _readU32BE(data, mvhd + 20);
    final duration = _readU32BE(data, mvhd + 24);
    if (timescale > 0 && duration > 0) {
      return (duration / timescale).ceil();
    }
  } else if (version == 1) {
    if (mvhd + 32 > data.length) return null;
    final timescale = _readU32BE(data, mvhd + 28);
    final durationHigh = _readU32BE(data, mvhd + 32);
    final durationLow = _readU32BE(data, mvhd + 36);
    final duration = (durationHigh << 32) | durationLow;
    if (timescale > 0 && duration > 0) {
      return (duration / timescale).ceil();
    }
  }
  return null;
}

int? _findAscii(Uint8List data, String needle) {
  final pattern = needle.codeUnits;
  final limit = data.length - pattern.length;
  for (var i = 0; i <= limit; i++) {
    var matched = true;
    for (var j = 0; j < pattern.length; j++) {
      if (data[i + j] != pattern[j]) {
        matched = false;
        break;
      }
    }
    if (matched) return i;
  }
  return null;
}
