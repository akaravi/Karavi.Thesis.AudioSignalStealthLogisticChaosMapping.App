/// Thrown when a payload needs more LSB bits than the cover audio capacity.
class CapacityExceededException implements Exception {
  final int neededBits;
  final int availableBits;

  const CapacityExceededException({
    required this.neededBits,
    required this.availableBits,
  });

  /// Matches engine messages: `Message too long: needs N bits, capacity M`.
  static CapacityExceededException? tryParse(Object error) {
    if (error is CapacityExceededException) return error;
    final text = error.toString();
    final match = RegExp(
      r'needs\s+(\d+)\s+bits.*?capacity\s+(\d+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;
    final needed = int.tryParse(match.group(1)!);
    final available = int.tryParse(match.group(2)!);
    if (needed == null || available == null) return null;
    return CapacityExceededException(
      neededBits: needed,
      availableBits: available,
    );
  }

  @override
  String toString() =>
      'Message too long: needs $neededBits bits, capacity $availableBits';
}
