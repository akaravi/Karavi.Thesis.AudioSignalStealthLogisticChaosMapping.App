import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/logistic_param_bounds.dart';
import 'directional_text_field.dart';

/// Slider + manual numeric field for one logistic parameter with range guard.
class LogisticParamField extends StatefulWidget {
  final String label;
  final String rangeHint;
  final String invalidHint;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final int fractionDigits;
  final ValueChanged<double> onChanged;

  const LogisticParamField({
    super.key,
    required this.label,
    required this.rangeHint,
    required this.invalidHint,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.fractionDigits,
    required this.onChanged,
  });

  @override
  State<LogisticParamField> createState() => _LogisticParamFieldState();
}

class _LogisticParamFieldState extends State<LogisticParamField> {
  late final TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(LogisticParamField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.value != widget.value) {
      _ctrl.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _format(double v) => v.toStringAsFixed(widget.fractionDigits);

  void _commitFromField() {
    _editing = false;
    final parsed = widget.fractionDigits >= 3
        ? LogisticParamBounds.tryParseR(_ctrl.text)
        : LogisticParamBounds.tryParseX0(_ctrl.text);
    if (parsed == null) {
      _ctrl.text = _format(widget.value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.invalidHint)),
      );
      return;
    }
    widget.onChanged(parsed);
    _ctrl.text = _format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    final hintStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label, style: labelStyle),
                  const SizedBox(height: 2),
                  Text(widget.rangeHint, style: hintStyle),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 96,
              child: DirectionalTextField(
                forceLatinLtr: true,
                controller: _ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onTap: () => _editing = true,
                onSubmitted: (_) => _commitFromField(),
                onEditingComplete: _commitFromField,
                onTapOutside: (_) => _commitFromField(),
              ),
            ),
          ],
        ),
        Slider(
          value: widget.value.clamp(widget.min, widget.max),
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          label: _format(widget.value),
          onChanged: (v) {
            _editing = false;
            _ctrl.text = _format(v);
            widget.onChanged(v);
          },
        ),
      ],
    );
  }
}
