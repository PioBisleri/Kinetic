import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
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

  final double x, y; // center, fraction of panel
  final double w, h; // size, fraction of panel
  final double rotation; // radians
}

/// Front-view placements, defined for the LEFT side; `_r` nodes mirror
/// across the center line. Solo nodes have no left/right split.
const _frontLeft = <String, BodyRegion>{
  'front.upper_chest_l': BodyRegion(0.42, 0.175, 0.14, 0.055),
  'front.chest_l': BodyRegion(0.41, 0.225, 0.16, 0.085),
  'front.front_delts_l':
      BodyRegion(0.315, 0.185, 0.11, 0.09, rotation: 0.35),
  'front.side_delts_l':
      BodyRegion(0.272, 0.235, 0.08, 0.10, rotation: 0.25),
  'front.biceps_l': BodyRegion(0.238, 0.32, 0.085, 0.12, rotation: 0.2),
  'front.forearms_l':
      BodyRegion(0.2, 0.46, 0.07, 0.14, rotation: 0.14),
  'front.obliques_l':
      BodyRegion(0.397, 0.385, 0.075, 0.14, rotation: -0.1),
  'front.quads_l':
      BodyRegion(0.417, 0.645, 0.115, 0.20, rotation: 0.04),
};
const _frontSolo = <String, BodyRegion>{
  'front.rectus_abs': BodyRegion(0.5, 0.37, 0.15, 0.19),
};

const _backLeft = <String, BodyRegion>{
  'back.traps_l': BodyRegion(0.418, 0.17, 0.14, 0.085),
  'back.rear_delts_l':
      BodyRegion(0.315, 0.19, 0.11, 0.085, rotation: 0.35),
  'back.rhomboids_l': BodyRegion(0.43, 0.24, 0.11, 0.075),
  'back.lats_l': BodyRegion(0.397, 0.305, 0.13, 0.14, rotation: -0.14),
  'back.triceps_l': BodyRegion(0.238, 0.32, 0.085, 0.12, rotation: 0.2),
  'back.hams_l':
      BodyRegion(0.417, 0.635, 0.115, 0.19, rotation: 0.04),
  'back.calves_l':
      BodyRegion(0.432, 0.82, 0.09, 0.15, rotation: 0.03),
};
const _backSolo = <String, BodyRegion>{
  'back.spinal_erectors': BodyRegion(0.5, 0.31, 0.085, 0.24),
  'back.glutes': BodyRegion(0.5, 0.49, 0.24, 0.11),
};

/// All regions for a view (`front` | `back`); `_r` nodes are the mirrors
/// of their `_l` definitions.
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

/// Front/back body diagram with muscle regions coloured by freshness.
class BodyHeatMap extends ConsumerWidget {
  const BodyHeatMap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(muscleWindowProvider).value;
    final muscles = ref.watch(musclesProvider).value;

    if (window == null || muscles == null) {
      return const ChartCard(
        title: 'Body Heat Map',
        subtitle: 'freshness fades red → grey over 72h',
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
    for (final m in muscles) {
      final w = window[m.id];
      final freshness = w?.lastTrained == null
          ? 0.0
          : GradeEngine.freshness(
              hoursSinceTrained: w!.hoursSinceTrained(now),
            );
      final color = heatColorFor(freshness);
      for (final node in _parseNodes(m.heatmapNodes)) {
        if (node.startsWith('front.')) {
          front[node] = color;
        } else if (node.startsWith('back.')) {
          back[node] = color;
        }
      }
    }

    return ChartCard(
      title: 'Body Heat Map',
      subtitle: 'freshness fades red → grey over 72h',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _BodyPanel(view: 'front', nodes: front)),
              const SizedBox(width: 16),
              Expanded(child: _BodyPanel(view: 'back', nodes: back)),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeatLegend(color: AppColors.heatHot, label: 'Fresh'),
              SizedBox(width: 14),
              _HeatLegend(color: AppColors.heatWarm, label: 'Fading'),
              SizedBox(width: 14),
              _HeatLegend(color: AppColors.heatRest, label: 'Rest'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyPanel extends StatelessWidget {
  const _BodyPanel({required this.view, required this.nodes});

  final String view;
  final Map<String, Color> nodes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          view.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: context.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 0.52, // width / height — a standing figure
          child: CustomPaint(
            key: Key('heat-$view'),
            painter: _BodyPainter(
              view: view,
              nodes: nodes,
              elevated: context.surfaceElevated,
              border: context.border,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ],
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
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: context.textTertiary),
        ),
      ],
    );
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.view,
    required this.nodes,
    required this.elevated,
    required this.border,
  });

  final String view;
  final Map<String, Color> nodes;

  /// Colors resolved from the ambient theme in `build` — painters have no
  /// BuildContext of their own.
  final Color elevated;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fill = Paint()..color = elevated;
    final outline = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // --- silhouette ---------------------------------------------------
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0.5 * w, 0.06 * h),
        width: 0.11 * w,
        height: 0.115 * h,
      ),
      fill,
    );

    final torso = Path()
      ..moveTo(0.35 * w, 0.135 * h)
      ..lineTo(0.65 * w, 0.135 * h)
      ..lineTo(0.63 * w, 0.30 * h)
      ..lineTo(0.595 * w, 0.50 * h)
      ..lineTo(0.405 * w, 0.50 * h)
      ..lineTo(0.37 * w, 0.30 * h)
      ..close();
    canvas.drawPath(torso, fill);
    canvas.drawPath(torso, outline);

    Path limb(double ax, double ay, double bx, double by, double cx,
            double cy) =>
        Path()
          ..moveTo(ax * w, ay * h)
          ..lineTo(bx * w, by * h)
          ..lineTo(cx * w, cy * h);

    final arm = Paint()
      ..color = elevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.065 * w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(limb(0.36, 0.17, 0.27, 0.33, 0.21, 0.49), arm);
    canvas.drawPath(limb(0.64, 0.17, 0.73, 0.33, 0.79, 0.49), arm);

    final leg = Paint()
      ..color = elevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.09 * w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(limb(0.445, 0.49, 0.43, 0.71, 0.425, 0.95), leg);
    canvas.drawPath(limb(0.555, 0.49, 0.57, 0.71, 0.575, 0.95), leg);

    // --- muscle regions ----------------------------------------------
    final regions = regionsFor(view);
    for (final e in nodes.entries) {
      final r = regions[e.key];
      if (r == null) continue;
      final bw = r.w * w;
      final bh = r.h * h;
      canvas.save();
      canvas.translate(r.x * w, r.y * h);
      canvas.rotate(r.rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: bw, height: bh),
          Radius.circular(math.min(bw, bh) * 0.45),
        ),
        Paint()..color = e.value,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BodyPainter oldDelegate) =>
      oldDelegate.view != view || !mapEquals(oldDelegate.nodes, nodes);
}
