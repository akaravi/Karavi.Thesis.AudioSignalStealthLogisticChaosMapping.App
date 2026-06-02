/// Embedding path — `train/embed_message.m` `embed_mode`.
enum StegoEmbedMode {
  /// `xor_only`: message bits XOR logistic key, then LSB.
  xorOnly,

  /// `ae_xor`: 8-bit blocks through trained autoencoder, then XOR, then LSB.
  aeXor,
}

extension StegoEmbedModeJson on StegoEmbedMode {
  static StegoEmbedMode fromConfig(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'ae_xor':
      case 'aexor':
      case 'ae':
        return StegoEmbedMode.aeXor;
      case 'xor_only':
      case 'xoronly':
      case 'xor':
      default:
        return StegoEmbedMode.xorOnly;
    }
  }

  String get configValue => switch (this) {
        StegoEmbedMode.xorOnly => 'xor_only',
        StegoEmbedMode.aeXor => 'ae_xor',
      };
}
