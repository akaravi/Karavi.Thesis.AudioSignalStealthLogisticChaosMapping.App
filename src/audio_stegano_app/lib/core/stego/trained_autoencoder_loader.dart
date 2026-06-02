import 'package:flutter/services.dart';

import 'message_block_autoencoder.dart';

/// Loads bundled `assets/stego/trained_autoencoder.json` (from `trained_autoencoder.mat`).
class TrainedAutoencoderLoader {
  TrainedAutoencoderLoader._();

  static MessageBlockAutoencoder? _cached;

  static const assetPath = 'assets/stego/trained_autoencoder.json';

  static Future<String> loadJsonString() async {
    return rootBundle.loadString(assetPath);
  }

  static Future<MessageBlockAutoencoder> load() async {
    if (_cached != null) return _cached!;
    final raw = await loadJsonString();
    _cached = MessageBlockAutoencoder.fromJsonString(raw);
    return _cached!;
  }

  /// For isolates / tests when JSON is already in memory.
  static MessageBlockAutoencoder fromJsonString(String raw) {
    final net = MessageBlockAutoencoder.fromJsonString(raw);
    _cached ??= net;
    return net;
  }
}
