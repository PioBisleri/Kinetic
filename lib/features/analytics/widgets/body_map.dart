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

    // Minimal line-art figure: head, neck, torso, arms and legs merged
    // into ONE outline, so the heat can be clipped to the body and the
    // silhouette stroked without any internal seams.
    final body = _silhouette(w, h);

    canvas.save();
    canvas.clipPath(body);
    canvas.drawPath(body, Paint()..color = elevated);

    // Soft heat — each node is a blurred oval (feathered halo) with a
    // firmer core inside it. Clipping at the silhouette keeps the glow
    // from spilling past the outline; edges cut cleanly instead.
    final regions = regionsFor(view);
    for (final e in nodes.entries) {
      final r = regions[e.key];
      if (r == null) continue;
      final bw = r.w * w;
      final bh = r.h * h;
      canvas.save();
      canvas.translate(r.x * w, r.y * h);
      canvas.rotate(r.rotation);
      final sigma = math.max(1.5, math.min(bw, bh) * 0.34);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: bw, height: bh),
        Paint()
          ..color = e.value.withValues(alpha: 0.9)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: bw * 0.7,
          height: bh * 0.7,
        ),
        Paint()..color = e.value.withValues(alpha: 0.55),
      );
      canvas.restore();
    }
    canvas.restore();

    // Thin outline over everything — crisp edge, soft interior.
    canvas.drawPath(
      body,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_BodyPainter oldDelegate) =>
      oldDelegate.view != view || !mapEquals(oldDelegate.nodes, nodes);
}

/// The whole figure as a single merged path for a `w × h` panel.
///
/// Every subpath overlaps its neighbours (neck bridges head ↔ torso, limb
/// roots tuck inside the torso), so the unions form one connected contour
/// whose outline can be stroked seam-free.
Path _silhouette(double w, double h) {
  var body = Path()
    ..addOval(Rect.fromCenter(
      center: Offset(0.5 * w, 0.062 * h),
      width: 0.105 * w,
      height: 0.112 * h,
    ));
  body = Path.combine(PathOperation.union, body, _neck(w, h));
  body = Path.combine(PathOperation.union, body, _torso(w, h));

  // (joint chain as panel fractions, half-width as a fraction of w) —
  // centre lines match where the heat-map nodes sit.
  const limbs = <(List<(double, double)>, double)>[
    ([(0.36, 0.165), (0.272, 0.33), (0.212, 0.485)], 0.033), // left arm
    ([(0.64, 0.165), (0.728, 0.33), (0.788, 0.485)], 0.033), // right arm
    ([(0.447, 0.49), (0.432, 0.715), (0.427, 0.945)], 0.045), // left leg
    ([(0.553, 0.49), (0.568, 0.715), (0.573, 0.945)], 0.045), // right leg
  ];
  for (final (joints, radius) in limbs) {
    for (var i = 0; i < joints.length - 1; i++) {
      final a = Offset(joints[i].$1 * w, joints[i].$2 * h);
      final b = Offset(joints[i + 1].$1 * w, joints[i + 1].$2 * h);
      body = Path.combine(PathOperation.union, body, _capsule(a, b, radius * w));
    }
  }
  return body;
}

Path _neck(double w, double h) => Path()
  ..moveTo(0.468 * w, 0.098 * h)
  ..lineTo(0.532 * w, 0.098 * h)
  ..lineTo(0.528 * w, 0.165 * h)
  ..lineTo(0.472 * w, 0.165 * h)
  ..close();

/// Shoulders → armpits → waist → hips, traced left-to-right across the
/// top so the winding matches the ovals (irrelevant for `union`, but it
/// keeps the path well-formed for stroking).
Path _torso(double w, double h) => Path()
  ..moveTo(0.345 * w, 0.148 * h)
  ..quadraticBezierTo(0.5 * w, 0.126 * h, 0.655 * w, 0.148 * h)
  ..quadraticBezierTo(0.668 * w, 0.235 * h, 0.625 * w, 0.305 * h)
  ..quadraticBezierTo(0.602 * w, 0.40 * h, 0.588 * w, 0.50 * h)
  ..lineTo(0.412 * w, 0.50 * h)
  ..quadraticBezierTo(0.398 * w, 0.40 * h, 0.375 * w, 0.305 * h)
  ..quadraticBezierTo(0.332 * w, 0.235 * h, 0.345 * w, 0.148 * h)
  ..close();

/// A rounded limb segment from [a] to [b]: a rectangle along the axis
/// plus joint circles at both ends (they overlap the neighbours, so the
/// union is a smooth capsule chain).
Path _capsule(Offset a, Offset b, double r) {
  final d = b - a;
  final len = d.distance;
  if (len < 0.0001) {
    return Path()..addOval(Rect.fromCircle(center: a, radius: r));
  }
  final u = Offset(d.dx / len, d.dy / len);
  final n = Offset(-u.dy, u.dx); // perpendicular, a quarter turn
  final p1 = a + n * r;
  final p2 = b + n * r;
  final p3 = b - n * r;
  final p4 = a - n * r;
  return Path()
    ..moveTo(p4.dx, p4.dy)
    ..lineTo(p3.dx, p3.dy)
    ..lineTo(p2.dx, p2.dy)
    ..lineTo(p1.dx, p1.dy)
    ..close()
    ..addOval(Rect.fromCircle(center: a, radius: r))
    ..addOval(Rect.fromCircle(center: b, radius: r));
}
