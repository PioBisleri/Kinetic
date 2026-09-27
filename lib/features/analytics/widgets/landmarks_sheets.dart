import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/landmark_store.dart';
import '../domain/volume_landmarks.dart';
import '../../../core/database/database.dart';
import '../../../core/theme/app_theme.dart';
import 'landmarks_card.dart' show zoneColor;

/// "How landmarks work" — the sheet behind the card's info button
/// (Round 6): the three definitions, how sets are counted, and a zone
/// legend, so every number on the card is accounted for.
Future<void> showLandmarksInfoSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      builder: (_) => const _LandmarksInfoSheet(),
    );

class _LandmarksInfoSheet extends StatelessWidget {
  const _LandmarksInfoSheet();

  @override
  Widget build(BuildContext context) {
    const defs = [
      ('MEV', 'Minimum effective',
          'Below this many hard sets a week, a muscle is unlikely to grow.'),
      ('MAV', 'Maximum adaptive',
          'Top of the productive sweet spot — past it, returns shrink '
              'while recovery cost keeps rising.'),
      ('MRV', 'Maximum recoverable',
          'Beyond this, recovery lags behind stimulus — junk volume.'),
    ];
    const legend = [
      (LandmarkZone.belowMev, 'Under MEV'),
      (LandmarkZone.productive, 'Sweet spot'),
      (LandmarkZone.aboveMav, 'Diminishing'),
      (LandmarkZone.aboveMrv, 'Past MRV'),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How landmarks work',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
            ),
            const SizedBox(height: 12),
            for (final (code, name, blurb) in defs) ...[
              Row(
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  blurb,
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'How sets are counted',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Hard sets credited to the muscle per week — the same sets '
              'that feed the volume charts. The window follows the period '
              'chips above the card.',
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              'The numbers ship as curated defaults. Tap any muscle to '
              'adjust its bands or reset them.',
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                for (final (zone, label) in legend)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: zoneColor(context, zone, bright: true),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                            fontSize: 11, color: context.textTertiary),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The per-muscle editor: three whole-number fields, one save rule
/// (1 ≤ MEV < MAV < MRV ≤ 99), and a reset back to the curated default.
Future<void> showLandmarkEditSheet(
  BuildContext context, {
  required String muscleId,
  required String name,
  required Landmark landmark,
  required bool edited,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
    ),
    builder: (_) => Padding(
      // Keep the fields above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _LandmarkEditSheet(
        muscleId: muscleId,
        name: name,
        landmark: landmark,
        edited: edited,
      ),
    ),
  );
}

class _LandmarkEditSheet extends ConsumerStatefulWidget {
  const _LandmarkEditSheet({
    required this.muscleId,
    required this.name,
    required this.landmark,
    required this.edited,
  });

  final String muscleId;
  final String name;
  final Landmark landmark;
  final bool edited;

  @override
  ConsumerState<_LandmarkEditSheet> createState() =>
      _LandmarkEditSheetState();
}

class _LandmarkEditSheetState extends ConsumerState<_LandmarkEditSheet> {
  late final TextEditingController _mev;
  late final TextEditingController _mav;
  late final TextEditingController _mrv;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mev = TextEditingController(text: widget.landmark.mev.toString());
    _mav = TextEditingController(text: widget.landmark.mav.toString());
    _mrv = TextEditingController(text: widget.landmark.mrv.toString());
  }

  @override
  void dispose() {
    _mev.dispose();
    _mav.dispose();
    _mrv.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final mev = int.tryParse(_mev.text.trim());
    final mav = int.tryParse(_mav.text.trim());
    final mrv = int.tryParse(_mrv.text.trim());
    if (mev == null || mav == null || mrv == null) {
      setState(() => _error = 'Enter three whole numbers');
      return;
    }
    final lm = Landmark(mev: mev, mav: mav, mrv: mrv);
    if (!lm.isValid) {
      setState(
          () => _error = 'Keep them ordered: 1 ≤ MEV < MAV < MRV ≤ 99');
      return;
    }
    await LandmarkStore(ref.read(databaseProvider)).save(widget.muscleId, lm);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _reset() async {
    await LandmarkStore(ref.read(databaseProvider)).reset(widget.muscleId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Edit landmarks',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4),
                ),
              ),
              if (widget.edited)
                Text(
                  'edited',
                  style: TextStyle(fontSize: 12, color: AppColors.accent),
                ),
            ],
          ),
          Text(
            '${widget.name} · hard sets per week',
            style: TextStyle(color: context.textSecondary),
          ),
          const SizedBox(height: 16),
          _FieldRow(
            label: 'MEV',
            hint: 'minimum',
            controller: _mev,
            fieldKey: const Key('landmark-mev-input'),
          ),
          const SizedBox(height: 12),
          _FieldRow(
            label: 'MAV',
            hint: 'sweet spot top',
            controller: _mav,
            fieldKey: const Key('landmark-mav-input'),
          ),
          const SizedBox(height: 12),
          _FieldRow(
            label: 'MRV',
            hint: 'recoverable ceiling',
            controller: _mrv,
            fieldKey: const Key('landmark-mrv-input'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              key: const Key('landmark-error'),
              style: TextStyle(fontSize: 12, color: AppColors.heatHot),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              if (widget.edited)
                TextButton(
                  key: const Key('landmark-reset'),
                  onPressed: _reset,
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.heatHot),
                  child: const Text('Reset'),
                ),
              const Spacer(),
              Expanded(
                child: FilledButton(
                  key: const Key('landmark-save'),
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.hint,
    required this.controller,
    required this.fieldKey,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final Key fieldKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 46,
          child: Text(
            label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.textPrimary),
          ),
        ),
        Expanded(
          child: TextField(
            key: fieldKey,
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()]),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 12, color: context.textTertiary),
            ),
          ),
        ),
        const SizedBox(width: 46), // balance the label column
      ],
    );
  }
}
