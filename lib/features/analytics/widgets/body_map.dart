import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/ledger/ledger.dart';
import '../../../core/theme/app_theme.dart';
import '../application/analytics_providers.dart';
import '../domain/grade_engine.dart';
import 'charts.dart';

/// Red → grey over 72h: heat for fresh work, cold grey for rest.
Color heatColorFor(double freshness) {
  final f = freshness.clamp(0.0, 1.0);
  if (f >= 0.5) {
    return Color.lerp(AppColors.heatWarm, AppColors.heatHot, (f - 0.5) * 2)!;
  }
  return Color.lerp(AppColors.heatRest, AppColors.heatWarm, f * 2)!;
}

/// Normalized (0..1) placement of one heat-map node on a body view.
class BodyRegion {
  const BodyRegion(this.x, this.y, this.w, this.h, {this.rotation = 0});

  final double x, y;
  final double w, h;
  final double rotation;
}

const _frontLeft = <String, BodyRegion>{
  'front.upper_chest_l': BodyRegion(0.434, 0.188, 0.135, 0.052),
  'front.chest_l': BodyRegion(0.431, 0.239, 0.150, 0.100),
  'front.front_delts_l': BodyRegion(0.358, 0.191, 0.100, 0.088, rotation: 0.18),
  'front.side_delts_l': BodyRegion(0.314, 0.220, 0.076, 0.082, rotation: 0.25),
  'front.biceps_l': BodyRegion(0.299, 0.288, 0.076, 0.130, rotation: 0.12),
  'front.forearms_l': BodyRegion(0.262, 0.428, 0.062, 0.148, rotation: 0.11),
  'front.obliques_l': BodyRegion(0.430, 0.390, 0.060, 0.132, rotation: -0.04),
  'front.quads_l': BodyRegion(0.437, 0.650, 0.116, 0.210, rotation: 0.02),
};
const _frontSolo = <String, BodyRegion>{
  'front.rectus_abs': BodyRegion(0.5, 0.372, 0.125, 0.182),
};

const _backLeft = <String, BodyRegion>{
  'back.traps_l': BodyRegion(0.430, 0.178, 0.150, 0.090),
  'back.rear_delts_l': BodyRegion(0.358, 0.200, 0.100, 0.085, rotation: 0.18),
  'back.rhomboids_l': BodyRegion(0.435, 0.246, 0.110, 0.066),
  'back.lats_l': BodyRegion(0.422, 0.330, 0.136, 0.160, rotation: -0.08),
  'back.triceps_l': BodyRegion(0.299, 0.288, 0.076, 0.130, rotation: 0.12),
  'back.hams_l': BodyRegion(0.437, 0.640, 0.116, 0.200, rotation: 0.02),
  'back.calves_l': BodyRegion(0.438, 0.835, 0.095, 0.160, rotation: 0.02),
};
const _backSolo = <String, BodyRegion>{
  'back.spinal_erectors': BodyRegion(0.5, 0.325, 0.075, 0.230),
  'back.glutes': BodyRegion(0.5, 0.500, 0.220, 0.115),
};

Map<String, BodyRegion> regionsFor(String view) {
  final left = view == 'front' ? _frontLeft : _backLeft;
  final solo = view == 'front' ? _frontSolo : _backSolo;
  return {
    for (final e in left.entries) ...{
      e.key: e.value,
      e.key.replaceFirst('_l', '_r'): BodyRegion(
        1 - e.value.x,
        e.value.y,
        e.value.w,
        e.value.h,
        rotation: -e.value.rotation,
      ),
    },
    ...solo,
  };
}

List<String> _parseNodes(String json) {
  try {
    return (jsonDecode(json) as List).cast<String>();
  } catch (_) {
    return const [];
  }
}

String _heatState(double freshness) {
  if (freshness >= 0.66) return 'FRESH';
  if (freshness >= 0.2) return 'FADING';
  return 'REST';
}

typedef _NodeInfo = ({String name, double freshness});

/// One large front/back plate with flat, crisp muscle regions.
class BodyHeatMap extends ConsumerStatefulWidget {
  const BodyHeatMap({super.key});

  @override
  ConsumerState<BodyHeatMap> createState() => _BodyHeatMapState();
}

class _BodyHeatMapState extends ConsumerState<BodyHeatMap> {
  bool _front = true;
  String? _selected;

  void _selectAt(Offset local, Size size, Map<String, Color> nodes) {
    final view = _front ? 'front' : 'back';
    final regions = regionsFor(view);
    String? hit;
    var best = double.infinity;
    for (final key in nodes.keys) {
      final r = regions[key];
      if (r == null) continue;
      final dx = local.dx - r.x * size.width;
      final dy = local.dy - r.y * size.height;
      final cos = math.cos(-r.rotation);
      final sin = math.sin(-r.rotation);
      final rx = dx * cos - dy * sin;
      final ry = dx * sin + dy * cos;
      final nx = rx / (r.w * size.width * 0.58);
      final ny = ry / (r.h * size.height * 0.58);
      final distance = nx * nx + ny * ny;
      if (distance <= 1 && distance < best) {
        best = distance;
        hit = key;
      }
    }
    setState(() => _selected = hit == _selected ? null : hit);
  }

  @override
  Widget build(BuildContext context) {
    final window = ref.watch(muscleWindowProvider).value;
    final muscles = ref.watch(musclesProvider).value;

    if (window == null || muscles == null) {
      return const ChartCard(
        title: 'Muscle map',
        subtitle: 'freshness fades hot → grey over 72h',
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final front = <String, Color>{};
    final back = <String, Color>{};
    final info = <String, _NodeInfo>{};
    for (final m in muscles) {
      final w = window[m.id];
      final freshness = w?.lastTrained == null
          ? 0.0
          : GradeEngine.freshness(hoursSinceTrained: w!.hoursSinceTrained(now));
      final color = heatColorFor(freshness);
      for (final node in _parseNodes(m.heatmapNodes)) {
        if (node.startsWith('front.')) {
          front[node] = color;
        } else if (node.startsWith('back.')) {
          back[node] = color;
        }
        info[node] = (name: m.name, freshness: freshness);
      }
    }

    final view = _front ? 'front' : 'back';
    final nodes = _front ? front : back;
    final selected = _selected != null && nodes.containsKey(_selected)
        ? _selected
        : null;
    final selectedInfo = selected == null ? null : info[selected];

    return ChartCard(
      title: 'Muscle map',
      subtitle: 'freshness fades hot → grey over 72h',
      child: Column(
        children: [
          _ViewToggle(
            front: _front,
            onChanged: (frontValue) => setState(() {
              _front = frontValue;
              _selected = null;
            }),
          ),
          const SizedBox(height: 14),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 244),
              child: AspectRatio(
                aspectRatio: 0.52,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) =>
                          _selectAt(details.localPosition, size, nodes),
                      child: Semantics(
                        label:
                            '${_front ? 'Front' : 'Back'} muscle map. '
                            'Tap a muscle to inspect it.',
                        child: CustomPaint(
                          key: const Key('heat-figure'),
                          painter: _BodyPainter(
                            view: view,
                            nodes: nodes,
                            selected: selected,
                            surface: context.surface,
                            elevated: context.surfaceElevated,
                            border: context.border,
                            highlight: context.textPrimary,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 244),
              child: _SelectedMuscleBar(
                name: selectedInfo?.name,
                freshness: selectedInfo?.freshness,
                color: selected == null ? null : nodes[selected],
                onClear: () => setState(() => _selected = null),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeatLegend(color: AppColors.heatHot, label: 'Fresh'),
              SizedBox(width: 16),
              _HeatLegend(color: AppColors.heatWarm, label: 'Fading'),
              SizedBox(width: 16),
              _HeatLegend(color: AppColors.heatRest, label: 'Rest'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedMuscleBar extends StatelessWidget {
  const _SelectedMuscleBar({
    required this.name,
    required this.freshness,
    required this.color,
    required this.onClear,
  });

  final String? name;
  final double? freshness;
  final Color? color;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final selected = name != null && freshness != null && color != null;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: context.border),
        borderRadius: BorderRadius.circular(AppRadius.data),
      ),
      child: selected
          ? Row(
              children: [
                Container(width: 8, height: 8, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name!,
                    key: const Key('heat-muscle-label'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.bodySm.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                Text(
                  _heatState(freshness!),
                  style: AppType.metaSm.copyWith(
                    color: context.textTertiary,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  key: const Key('heat-clear'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onClear,
                  child: LedgerGlyph(
                    LedgerGlyphType.close,
                    size: 12,
                    color: context.textTertiary,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                LedgerGlyph(
                  LedgerGlyphType.search,
                  size: 13,
                  color: context.textTertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'TAP A MUSCLE TO INSPECT',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.metaSm.copyWith(
                      color: context.textTertiary,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.front, required this.onChanged});

  final bool front;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget cell(String key, bool active, String label, bool isFront) {
      return Expanded(
        child: InkWell(
          key: Key(key),
          onTap: () => onChanged(isFront),
          splashColor: context.accent.withValues(alpha: 0.06),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: active
                  ? context.accent.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: isFront
                  ? null
                  : Border(left: BorderSide(color: context.border)),
            ),
            child: Center(
              child: Text(
                label,
                style: AppType.meta.copyWith(
                  color: active ? context.accent : context.textSecondary,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: context.border),
        borderRadius: BorderRadius.circular(AppRadius.data),
      ),
      child: Row(
        children: [
          cell('heat-front', front, '01  FRONT', true),
          cell('heat-back', !front, '02  BACK', false),
        ],
      ),
    );
  }
}

class _HeatLegend extends StatelessWidget {
  const _HeatLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, color: color),
        const SizedBox(width: 5),
        Text(
          label.toUpperCase(),
          style: AppType.metaSm.copyWith(color: context.textTertiary),
        ),
      ],
    );
  }
}

enum _MuscleForm {
  pec,
  pecUpper,
  delt,
  bicep,
  tricep,
  forearm,
  oblique,
  abs,
  quad,
  ham,
  calf,
  trap,
  rhomboid,
  lat,
  erector,
  glute,
  lens,
}

_MuscleForm _formFor(String node) {
  final base = node.replaceFirst(RegExp(r'_[lr]$'), '');
  return switch (base) {
    'front.chest' => _MuscleForm.pec,
    'front.upper_chest' => _MuscleForm.pecUpper,
    'front.front_delts' ||
    'front.side_delts' ||
    'back.rear_delts' => _MuscleForm.delt,
    'front.biceps' => _MuscleForm.bicep,
    'back.triceps' => _MuscleForm.tricep,
    'front.forearms' => _MuscleForm.forearm,
    'front.obliques' => _MuscleForm.oblique,
    'front.rectus_abs' => _MuscleForm.abs,
    'front.quads' => _MuscleForm.quad,
    'back.hams' => _MuscleForm.ham,
    'back.calves' => _MuscleForm.calf,
    'back.traps' => _MuscleForm.trap,
    'back.rhomboids' => _MuscleForm.rhomboid,
    'back.lats' => _MuscleForm.lat,
    'back.spinal_erectors' => _MuscleForm.erector,
    'back.glutes' => _MuscleForm.glute,
    _ => _MuscleForm.lens,
  };
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.view,
    required this.nodes,
    required this.selected,
    required this.surface,
    required this.elevated,
    required this.border,
    required this.highlight,
  });

  final String view;
  final Map<String, Color> nodes;
  final String? selected;
  final Color surface;
  final Color elevated;
  final Color border;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = _silhouette(w, h);

    canvas.save();
    canvas.clipPath(body);
    canvas.drawPath(body, Paint()..color = elevated);

    final regions = regionsFor(view);
    for (final e in nodes.entries) {
      if (e.key == selected) continue;
      final r = regions[e.key];
      if (r == null) continue;
      _paintNode(canvas, size, e.key, r, e.value, false);
    }
    if (selected != null) {
      final r = regions[selected];
      final color = nodes[selected];
      if (r != null && color != null) {
        _paintNode(canvas, size, selected!, r, color, true);
      }
    }
    _paintAnatomy(canvas, size, view);
    canvas.restore();

    canvas.drawPath(
      body,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _paintNode(
    Canvas canvas,
    Size size,
    String key,
    BodyRegion r,
    Color color,
    bool isSelected,
  ) {
    final bw = r.w * size.width;
    final bh = r.h * size.height;
    final rest = color == AppColors.heatRest;
    final form = _formFor(key);
    final mirror = key.endsWith('_r');

    canvas.save();
    canvas.translate(r.x * size.width, r.y * size.height);
    canvas.rotate(r.rotation);
    if (mirror) canvas.scale(-1, 1);
    if (isSelected) canvas.scale(1.14);

    final rect = Rect.fromCenter(center: Offset.zero, width: bw, height: bh);
    final path = _formPath(form, rect);
    canvas.drawPath(
      path,
      Paint()..color = color.withValues(alpha: rest ? 0.50 : 0.90),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = surface.withValues(alpha: rest ? 0.16 : 0.26)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
    if (isSelected) {
      canvas.drawPath(
        path,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = highlight.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    canvas.restore();
  }

  Path _formPath(_MuscleForm form, Rect r) {
    final w = r.width / 2;
    final h = r.height / 2;
    switch (form) {
      case _MuscleForm.pec:
        return Path()
          ..moveTo(w * 0.92, -h * 0.55)
          ..quadraticBezierTo(w * 0.15, -h * 0.64, -w * 0.22, -h * 0.50)
          ..quadraticBezierTo(-w * 0.72, -h * 0.28, -w * 0.48, h * 0.05)
          ..quadraticBezierTo(-w * 0.30, h * 0.45, w * 0.05, h * 0.62)
          ..quadraticBezierTo(w * 0.58, h * 0.40, w * 0.92, -h * 0.55)
          ..close();
      case _MuscleForm.pecUpper:
        return Path()
          ..moveTo(w * 0.92, -h * 0.62)
          ..quadraticBezierTo(-w * 0.10, -h * 0.95, -w * 0.70, -h * 0.35)
          ..quadraticBezierTo(-w * 0.74, h * 0.12, -w * 0.18, h * 0.42)
          ..quadraticBezierTo(w * 0.40, h * 0.48, w * 0.92, -h * 0.62)
          ..close();
      case _MuscleForm.delt:
        return Path()
          ..moveTo(-w * 0.55, h * 0.25)
          ..quadraticBezierTo(-w * 0.65, -h * 0.55, 0, -h * 0.70)
          ..quadraticBezierTo(w * 0.70, -h * 0.45, w * 0.55, h * 0.15)
          ..quadraticBezierTo(w * 0.30, h * 0.55, 0, h * 0.50)
          ..quadraticBezierTo(-w * 0.25, h * 0.55, -w * 0.55, h * 0.25)
          ..close();
      case _MuscleForm.bicep:
        return Path()
          ..moveTo(0, -h * 0.55)
          ..quadraticBezierTo(w * 0.55, -h * 0.20, w * 0.45, h * 0.15)
          ..quadraticBezierTo(w * 0.38, h * 0.45, 0, h * 0.55)
          ..quadraticBezierTo(-w * 0.38, h * 0.42, -w * 0.42, h * 0.10)
          ..quadraticBezierTo(-w * 0.45, -h * 0.25, 0, -h * 0.55)
          ..close();
      case _MuscleForm.tricep:
        return Path()
          ..moveTo(w * 0.10, -h * 0.55)
          ..quadraticBezierTo(-w * 0.55, -h * 0.35, -w * 0.50, h * 0.12)
          ..quadraticBezierTo(-w * 0.45, h * 0.45, 0, h * 0.55)
          ..quadraticBezierTo(w * 0.40, h * 0.42, w * 0.45, h * 0.05)
          ..quadraticBezierTo(w * 0.35, -h * 0.30, w * 0.10, -h * 0.55)
          ..close();
      case _MuscleForm.forearm:
        return Path()
          ..moveTo(-w * 0.10, -h * 0.55)
          ..quadraticBezierTo(-w * 0.55, -h * 0.35, -w * 0.45, h * 0.30)
          ..quadraticBezierTo(-w * 0.35, h * 0.55, 0, h * 0.60)
          ..quadraticBezierTo(w * 0.35, h * 0.55, w * 0.30, h * 0.20)
          ..quadraticBezierTo(w * 0.25, -h * 0.35, w * 0.10, -h * 0.55)
          ..close();
      case _MuscleForm.oblique:
        return Path()
          ..moveTo(w * 0.65, -h * 0.52)
          ..quadraticBezierTo(-w * 0.45, -h * 0.45, -w * 0.60, 0)
          ..quadraticBezierTo(-w * 0.50, h * 0.45, w * 0.15, h * 0.55)
          ..quadraticBezierTo(w * 0.55, h * 0.25, w * 0.65, -h * 0.52)
          ..close();
      case _MuscleForm.abs:
        return Path()
          ..moveTo(-w * 0.80, -h * 0.50)
          ..quadraticBezierTo(0, -h * 0.62, w * 0.80, -h * 0.50)
          ..quadraticBezierTo(w * 0.92, h * 0.08, w * 0.58, h * 0.55)
          ..quadraticBezierTo(0, h * 0.64, -w * 0.58, h * 0.55)
          ..quadraticBezierTo(-w * 0.92, h * 0.08, -w * 0.80, -h * 0.50)
          ..close();
      case _MuscleForm.quad:
        return Path()
          ..moveTo(-w * 0.55, -h * 0.55)
          ..quadraticBezierTo(w * 0.45, -h * 0.60, w * 0.55, -h * 0.15)
          ..quadraticBezierTo(w * 0.45, h * 0.35, w * 0.12, h * 0.55)
          ..quadraticBezierTo(-w * 0.35, h * 0.50, -w * 0.50, h * 0.10)
          ..close();
      case _MuscleForm.ham:
        return Path()
          ..moveTo(-w * 0.35, -h * 0.55)
          ..quadraticBezierTo(w * 0.45, -h * 0.50, w * 0.50, h * 0.05)
          ..quadraticBezierTo(w * 0.40, h * 0.45, 0, h * 0.60)
          ..quadraticBezierTo(-w * 0.45, h * 0.40, -w * 0.50, 0)
          ..close();
      case _MuscleForm.calf:
        return Path()
          ..moveTo(-w * 0.15, -h * 0.55)
          ..quadraticBezierTo(w * 0.50, -h * 0.40, w * 0.55, h * 0.05)
          ..quadraticBezierTo(w * 0.50, h * 0.40, 0, h * 0.58)
          ..quadraticBezierTo(-w * 0.50, h * 0.40, -w * 0.50, h * 0.05)
          ..quadraticBezierTo(-w * 0.45, -h * 0.35, -w * 0.15, -h * 0.55)
          ..close();
      case _MuscleForm.trap:
        return Path()
          ..moveTo(w * 0.60, h * 0.50)
          ..quadraticBezierTo(0, h * 0.35, -w * 0.45, -h * 0.10)
          ..quadraticBezierTo(-w * 0.55, -h * 0.45, -w * 0.20, -h * 0.55)
          ..quadraticBezierTo(w * 0.30, -h * 0.45, w * 0.60, -h * 0.15)
          ..close();
      case _MuscleForm.rhomboid:
        return Path()
          ..moveTo(w * 0.55, -h * 0.50)
          ..quadraticBezierTo(-w * 0.10, -h * 0.60, -w * 0.55, -h * 0.35)
          ..lineTo(-w * 0.48, h * 0.45)
          ..quadraticBezierTo(w * 0.05, h * 0.55, w * 0.55, h * 0.30)
          ..close();
      case _MuscleForm.lat:
        return Path()
          ..moveTo(w * 0.50, -h * 0.55)
          ..quadraticBezierTo(-w * 0.55, -h * 0.45, -w * 0.60, h * 0.05)
          ..quadraticBezierTo(-w * 0.35, h * 0.50, w * 0.15, h * 0.60)
          ..quadraticBezierTo(w * 0.55, h * 0.25, w * 0.50, -h * 0.55)
          ..close();
      case _MuscleForm.erector:
        final lobe = Rect.fromCenter(
          center: Offset(-w * 0.22, 0),
          width: w * 0.62,
          height: h * 1.92,
        );
        final other = Rect.fromCenter(
          center: Offset(w * 0.22, 0),
          width: w * 0.62,
          height: h * 1.92,
        );
        final radius = Radius.circular(w * 0.24);
        return Path()
          ..addRRect(RRect.fromRectAndRadius(lobe, radius))
          ..addRRect(RRect.fromRectAndRadius(other, radius));
      case _MuscleForm.glute:
        final l = Rect.fromCenter(
          center: Offset(-w * 0.23, 0),
          width: w * 0.58,
          height: h * 0.94,
        );
        final rr = Rect.fromCenter(
          center: Offset(w * 0.23, 0),
          width: w * 0.58,
          height: h * 0.94,
        );
        final radius = Radius.circular(h * 0.42);
        return Path()
          ..addRRect(RRect.fromRectAndRadius(l, radius))
          ..addRRect(RRect.fromRectAndRadius(rr, radius));
      case _MuscleForm.lens:
        return Path()
          ..moveTo(0, -h * 0.55)
          ..quadraticBezierTo(w * 0.55, -h * 0.10, 0, h * 0.55)
          ..quadraticBezierTo(-w * 0.55, -h * 0.10, 0, -h * 0.55)
          ..close();
    }
  }

  void _paintAnatomy(Canvas canvas, Size size, String view) {
    final w = size.width;
    final h = size.height;
    final ink = border.withValues(alpha: 0.80);
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    if (view == 'front') {
      canvas.drawLine(
        Offset(0.5 * w, 0.125 * h),
        Offset(0.5 * w, 0.292 * h),
        line,
      );

      final collar = Path()
        ..moveTo(0.5 * w, 0.171 * h)
        ..quadraticBezierTo(0.435 * w, 0.158 * h, 0.382 * w, 0.184 * h);
      canvas.drawPath(collar, line);
      canvas.save();
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
      canvas.drawPath(collar, line);
      canvas.restore();

      canvas.drawLine(
        Offset(0.5 * w, 0.292 * h),
        Offset(0.5 * w, 0.462 * h),
        line,
      );
      for (var i = 1; i <= 3; i++) {
        final y = (0.292 + i * 0.043) * h;
        canvas.drawLine(Offset(0.462 * w, y), Offset(0.538 * w, y), line);
      }
      final v = Path()
        ..moveTo(0.466 * w, 0.478 * h)
        ..lineTo(0.5 * w, 0.535 * h)
        ..lineTo(0.534 * w, 0.478 * h);
      canvas.drawPath(v, line);
    } else {
      canvas.drawLine(
        Offset(0.5 * w, 0.132 * h),
        Offset(0.5 * w, 0.462 * h),
        line,
      );
      final scapula = Path()
        ..moveTo(0.462 * w, 0.202 * h)
        ..quadraticBezierTo(0.400 * w, 0.226 * h, 0.384 * w, 0.292 * h)
        ..quadraticBezierTo(0.415 * w, 0.320 * h, 0.462 * w, 0.300 * h);
      canvas.drawPath(scapula, line);
      canvas.save();
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
      canvas.drawPath(scapula, line);
      canvas.restore();

      canvas.drawLine(
        Offset(0.5 * w, 0.462 * h),
        Offset(0.5 * w, 0.555 * h),
        line,
      );
    }

    for (final y in [0.742]) {
      canvas.drawLine(Offset(0.405 * w, y * h), Offset(0.472 * w, y * h), line);
      canvas.drawLine(Offset(0.528 * w, y * h), Offset(0.595 * w, y * h), line);
    }
  }

  @override
  bool shouldRepaint(_BodyPainter oldDelegate) =>
      oldDelegate.view != view ||
      oldDelegate.selected != selected ||
      !mapEquals(oldDelegate.nodes, nodes) ||
      oldDelegate.surface != surface ||
      oldDelegate.elevated != elevated ||
      oldDelegate.border != border ||
      oldDelegate.highlight != highlight;
}

Path _silhouette(double w, double h) {
  var body = Path()
    ..addOval(
      Rect.fromCenter(
        center: Offset(0.5 * w, 0.068 * h),
        width: 0.110 * w,
        height: 0.120 * h,
      ),
    );
  body = Path.combine(PathOperation.union, body, _neck(w, h));
  body = Path.combine(PathOperation.union, body, _torso(w, h));
  body = Path.combine(PathOperation.union, body, _pelvis(w, h));

  const limbs = <(List<(double, double)>, List<double>)>[
    ([(0.354, 0.180), (0.296, 0.326), (0.247, 0.486)], [0.052, 0.033, 0.024]),
    ([(0.646, 0.180), (0.704, 0.326), (0.753, 0.486)], [0.052, 0.033, 0.024]),
    ([(0.447, 0.490), (0.438, 0.720), (0.432, 0.958)], [0.060, 0.044, 0.028]),
    ([(0.553, 0.490), (0.562, 0.720), (0.568, 0.958)], [0.060, 0.044, 0.028]),
  ];
  for (final (joints, radii) in limbs) {
    Path limb = Path();
    for (var i = 0; i < joints.length - 1; i++) {
      final a = Offset(joints[i].$1 * w, joints[i].$2 * h);
      final b = Offset(joints[i + 1].$1 * w, joints[i + 1].$2 * h);
      limb = Path.combine(
        PathOperation.union,
        limb,
        _taperedSegment(a, b, radii[i] * w, radii[i + 1] * w),
      );
    }
    body = Path.combine(PathOperation.union, body, limb);
  }
  for (final left in [true, false]) {
    body = Path.combine(PathOperation.union, body, _hand(w, h, left: left));
    body = Path.combine(PathOperation.union, body, _foot(w, h, left: left));
  }
  return body;
}

Path _pelvis(double w, double h) => Path()
  ..addOval(
    Rect.fromCenter(
      center: Offset(0.5 * w, 0.503 * h),
      width: 0.228 * w,
      height: 0.092 * h,
    ),
  );

Path _hand(double w, double h, {required bool left}) {
  final side = left ? -1.0 : 1.0;
  final wrist = Offset(0.5 * w + side * 0.253 * w, 0.486 * h);
  final tip = Offset(0.5 * w + side * 0.236 * w, 0.552 * h);
  final palm = Offset(0.5 * w + side * 0.240 * w, 0.530 * h);
  return Path.combine(
    PathOperation.union,
    _taperedSegment(wrist, tip, 0.024 * w, 0.014 * w),
    Path()..addOval(
      Rect.fromCenter(center: palm, width: 0.046 * w, height: 0.060 * h),
    ),
  );
}

Path _foot(double w, double h, {required bool left}) {
  final side = left ? -1.0 : 1.0;
  final ankle = Offset(0.5 * w + side * 0.068 * w, 0.945 * h);
  final toe = Offset(0.5 * w + side * 0.086 * w, 0.992 * h);
  return Path.combine(
    PathOperation.union,
    _taperedSegment(ankle, toe, 0.027 * w, 0.030 * w),
    Path()..addOval(
      Rect.fromCenter(
        center: Offset(0.5 * w + side * 0.080 * w, 0.984 * h),
        width: 0.058 * w,
        height: 0.034 * h,
      ),
    ),
  );
}

Path _neck(double w, double h) => Path()
  ..moveTo(0.466 * w, 0.100 * h)
  ..lineTo(0.534 * w, 0.100 * h)
  ..lineTo(0.528 * w, 0.170 * h)
  ..lineTo(0.472 * w, 0.170 * h)
  ..close();

Path _torso(double w, double h) => Path()
  ..moveTo(0.345 * w, 0.155 * h)
  ..quadraticBezierTo(0.380 * w, 0.136 * h, 0.432 * w, 0.133 * h)
  ..quadraticBezierTo(0.500 * w, 0.126 * h, 0.568 * w, 0.133 * h)
  ..quadraticBezierTo(0.620 * w, 0.136 * h, 0.655 * w, 0.155 * h)
  ..quadraticBezierTo(0.676 * w, 0.240 * h, 0.628 * w, 0.310 * h)
  ..quadraticBezierTo(0.612 * w, 0.370 * h, 0.605 * w, 0.425 * h)
  ..quadraticBezierTo(0.604 * w, 0.465 * h, 0.595 * w, 0.505 * h)
  ..lineTo(0.405 * w, 0.505 * h)
  ..quadraticBezierTo(0.396 * w, 0.465 * h, 0.395 * w, 0.425 * h)
  ..quadraticBezierTo(0.388 * w, 0.370 * h, 0.372 * w, 0.310 * h)
  ..quadraticBezierTo(0.324 * w, 0.240 * h, 0.345 * w, 0.155 * h)
  ..close();

Path _taperedSegment(Offset a, Offset b, double ra, double rb) {
  final d = b - a;
  final len = d.distance;
  if (len < 0.0001) {
    return Path()..addOval(Rect.fromCircle(center: a, radius: ra));
  }
  final u = Offset(d.dx / len, d.dy / len);
  final n = Offset(-u.dy, u.dx);
  final p1 = a + n * ra;
  final p2 = b + n * rb;
  final p3 = b - n * rb;
  final p4 = a - n * ra;
  return Path()
    ..moveTo(p1.dx, p1.dy)
    ..lineTo(p2.dx, p2.dy)
    ..lineTo(p3.dx, p3.dy)
    ..lineTo(p4.dx, p4.dy)
    ..close()
    ..addOval(Rect.fromCircle(center: a, radius: ra))
    ..addOval(Rect.fromCircle(center: b, radius: rb));
}
