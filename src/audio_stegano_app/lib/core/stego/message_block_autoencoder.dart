import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Port of MATLAB `feedforwardnet(10)` 8-10-8 with `tansig` — `train/train_autoencoder.m`.
class MessageBlockAutoencoder {
  final List<List<double>> _iw;
  final List<List<double>> _lw;
  final List<double> _b1;
  final List<double> _b2;

  const MessageBlockAutoencoder._(
    this._iw,
    this._lw,
    this._b1,
    this._b2,
  );

  static const int blockSize = 8;
  static const int hiddenSize = 10;

  factory MessageBlockAutoencoder.fromJson(Map<String, dynamic> json) {
    List<List<double>> readMatrix(String key) {
      final raw = json[key] as List<dynamic>;
      return raw
          .map(
            (row) => (row as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
          )
          .toList();
    }

    List<double> readVector(String key) =>
        (json[key] as List<dynamic>).map((e) => (e as num).toDouble()).toList();

    return MessageBlockAutoencoder._(
      readMatrix('iw'),
      readMatrix('lw'),
      readVector('b1'),
      readVector('b2'),
    );
  }

  factory MessageBlockAutoencoder.fromJsonString(String raw) =>
      MessageBlockAutoencoder.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );

  /// `round(net(double(msg_matrix)))` — column-major 8×N blocks flattened.
  List<int> encodeRounded(Uint8List msgBits) {
    if (msgBits.length % blockSize != 0) {
      throw ArgumentError('msgBits length must be a multiple of $blockSize');
    }
    final nBlocks = msgBits.length ~/ blockSize;
    final out = List<int>.filled(msgBits.length, 0);
    for (var b = 0; b < nBlocks; b++) {
      final x = List<double>.generate(
        blockSize,
        (i) => msgBits[b * blockSize + i].toDouble(),
      );
      final y = _forwardColumn(x);
      for (var i = 0; i < blockSize; i++) {
        out[b * blockSize + i] = y[i].round();
      }
    }
    return out;
  }

  /// `round(net(double(reshape(payload, 8, n_blocks))))` flattened.
  Uint8List decodeBits(Uint8List payload) {
    if (payload.length % blockSize != 0) {
      throw ArgumentError('payload length must be a multiple of $blockSize');
    }
    final nBlocks = payload.length ~/ blockSize;
    final out = Uint8List(payload.length);
    for (var b = 0; b < nBlocks; b++) {
      final x = List<double>.generate(
        blockSize,
        (i) => payload[b * blockSize + i].toDouble(),
      );
      final y = _forwardColumn(x);
      for (var i = 0; i < blockSize; i++) {
        out[b * blockSize + i] = y[i].round().clamp(0, 255) & 1;
      }
    }
    return out;
  }

  List<double> _forwardColumn(List<double> x) {
    final n1 = List<double>.filled(hiddenSize, 0);
    for (var j = 0; j < hiddenSize; j++) {
      var sum = _b1[j];
      for (var i = 0; i < blockSize; i++) {
        sum += _iw[j][i] * x[i];
      }
      n1[j] = _tansig(sum);
    }

    final out = List<double>.filled(blockSize, 0);
    for (var k = 0; k < blockSize; k++) {
      var sum = _b2[k];
      for (var j = 0; j < hiddenSize; j++) {
        sum += _lw[k][j] * n1[j];
      }
      out[k] = _tansig(sum);
    }
    return out;
  }

  static double _tansig(double n) =>
      2.0 / (1.0 + math.exp(-2.0 * n.clamp(-500.0, 500.0))) - 1.0;

  /// MATLAB `xor` on numeric values (non-zero is true), then LSB payload bit.
  static int xorPayloadBit(num encodedRounded, int keyBit) {
    final a = encodedRounded != 0;
    final b = keyBit != 0;
    return (a != b) ? 1 : 0;
  }

  /// Build XOR payload from `round(net(...))` and logistic key (embed path).
  static Uint8List buildPayload(List<int> encodedRounded, Uint8List key) {
    if (encodedRounded.length != key.length) {
      throw ArgumentError('encoded and key must have the same length');
    }
    final payload = Uint8List(encodedRounded.length);
    for (var i = 0; i < encodedRounded.length; i++) {
      payload[i] = xorPayloadBit(encodedRounded[i], key[i]);
    }
    return payload;
  }
}
