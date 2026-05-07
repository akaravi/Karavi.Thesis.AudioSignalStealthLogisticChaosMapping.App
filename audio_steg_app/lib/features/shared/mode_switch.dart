import 'package:flutter/material.dart';

import '../../app/app_strings.dart';
import '../../core/stego/stego.dart';

class StegoModeSwitch extends StatelessWidget {
  final StegoMode mode;
  final ValueChanged<StegoMode> onChanged;

  const StegoModeSwitch({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(s.mode, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<StegoMode>(
              segments: [
                ButtonSegment(
                  value: StegoMode.digital,
                  label: Text(s.modeDigital),
                  icon: const Icon(Icons.layers_outlined),
                ),
                ButtonSegment(
                  value: StegoMode.overTheAir,
                  label: Text(s.modeOverAir),
                  icon: const Icon(Icons.podcasts_outlined),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (set) => onChanged(set.first),
            ),
            const SizedBox(height: 8),
            Text(
              mode == StegoMode.digital ? s.modeDigitalDesc : s.modeOverAirDesc,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
