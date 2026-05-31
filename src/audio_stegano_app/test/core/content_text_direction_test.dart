import 'package:audio_stegano_app/core/ui/content_text_direction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContentTextDirection', () {
    test('empty follows locale', () {
      expect(
        ContentTextDirection.resolve('', localeDirection: TextDirection.rtl),
        TextDirection.rtl,
      );
      expect(
        ContentTextDirection.resolve('   ', localeDirection: TextDirection.rtl),
        TextDirection.rtl,
      );
    });

    test('Latin-only is LTR in RTL locale', () {
      expect(
        ContentTextDirection.resolve('hello 123', localeDirection: TextDirection.rtl),
        TextDirection.ltr,
      );
      expect(
        ContentTextDirection.resolve('3.99', localeDirection: TextDirection.rtl),
        TextDirection.ltr,
      );
    });

    test('RTL script is RTL', () {
      expect(
        ContentTextDirection.resolve('سلام', localeDirection: TextDirection.ltr),
        TextDirection.rtl,
      );
    });

    test('forceLatinLtr always LTR', () {
      expect(
        ContentTextDirection.resolve(
          'سلام',
          localeDirection: TextDirection.rtl,
          forceLatinLtr: true,
        ),
        TextDirection.ltr,
      );
    });

    test('email username password patterns are LTR in RTL locale', () {
      const samples = [
        'user@example.com',
        'karavi@ntk.ir',
        'User_Name-123',
        'P@ssw0rd!secret',
        'api_key_abc123',
      ];
      for (final sample in samples) {
        expect(
          ContentTextDirection.resolve(sample, localeDirection: TextDirection.rtl),
          TextDirection.ltr,
          reason: sample,
        );
        expect(
          ContentTextDirection.isLatinOnly(sample),
          isTrue,
          reason: sample,
        );
      }
    });
  });
}
