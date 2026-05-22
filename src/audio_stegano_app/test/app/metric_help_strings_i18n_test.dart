import 'package:audio_stegano_app/app/app_locale.dart';
import 'package:audio_stegano_app/app/app_strings.dart';
import 'package:audio_stegano_app/app/metric_help_strings.dart';
import 'package:audio_stegano_app/features/shared/embed_metric_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in AppLocale.values) {
    test('metric help strings non-empty for $locale', () {
      final s = AppStrings(locale);
      for (final kind in EmbedMetricKind.values) {
        expect(s.metricHelpTitle(kind).trim(), isNotEmpty);
        expect(s.metricHelpBody(kind).trim(), isNotEmpty);
      }
      expect(s.metricHelpTapHint.trim(), isNotEmpty);
      expect(s.embedWarningTitle.trim(), isNotEmpty);
      expect(s.errorTooLong.trim(), isNotEmpty);
    });
  }
}
