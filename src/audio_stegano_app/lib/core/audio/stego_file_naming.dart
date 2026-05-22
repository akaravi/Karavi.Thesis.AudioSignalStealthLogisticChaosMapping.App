/// Default stego WAV filename: stego_YYYY_MM_DD_HHMM_{msg_len}.wav
String stegoWavFileName(int msgBitLength, [DateTime? timestamp]) {
  final t = timestamp ?? DateTime.now();
  final y = t.year;
  final mo = t.month.toString().padLeft(2, '0');
  final d = t.day.toString().padLeft(2, '0');
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return 'stego_${y}_${mo}_${d}_$h${m}_$msgBitLength.wav';
}
