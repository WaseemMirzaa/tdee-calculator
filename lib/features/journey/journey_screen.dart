import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/journey_math.dart';
import '../../core/models/weigh_in.dart';
import '../../core/tdee_engine.dart';
import '../../core/theme/vita_tokens.dart';
import '../../core/theme/vita_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../widgets/vita.dart';

/// ★ S14 · Journey — the flagship differentiator. Turns a one-shot calculation
/// into a returning habit: log weigh-ins, watch a smoothed trend, simulate a
/// goal to a real date, and (Pro) recalibrate maintenance from your own data.
class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  double? _targetKg;
  double _rate = 0.5; // kg/week

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(resultProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final weighIns = ref.watch(weighInsProvider).valueOrNull ?? const <WeighIn>[];
    final v = context.vita;

    if (result == null || profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentKg = weighIns.isNotEmpty ? weighIns.last.weightKg : profile.weightKg;
    final target = _targetKg ?? _defaultTarget(currentKg, profile.goal);
    final losing = target < currentKg;
    final dailyDelta = (losing ? -1 : 1) * TdeeCalculator.dailyDeltaForRate(_rate);
    final weeks = JourneyMath.weeksToGoal(currentKg: currentKg, targetKg: target, dailyDeltaKcal: dailyDelta);
    final date = JourneyMath.projectedDate(
        currentKg: currentKg, targetKg: target, dailyDeltaKcal: dailyDelta, from: DateTime.now());
    final intakeTarget = result.maintenanceCalories + dailyDelta;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        Row(
          children: [
            Text('Journey', style: context.vt.titleLarge),
            const Spacer(),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: v.brand, foregroundColor: Colors.white),
              onPressed: () => _logWeighIn(currentKg),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Log weight'),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Current + change
        _StatStrip(weighIns: weighIns, currentKg: currentKg),
        const SizedBox(height: 14),

        // Trend chart
        if (weighIns.length >= 2)
          _TrendCard(weighIns: weighIns)
        else
          _EmptyTrend(onLog: () => _logWeighIn(currentKg)),
        const SizedBox(height: 14),

        // Goal simulator
        _SimulatorCard(
          currentKg: currentKg,
          targetKg: target,
          rate: _rate,
          weeks: weeks,
          date: date,
          dailyDelta: dailyDelta,
          intakeTarget: intakeTarget,
          onTarget: (t) => setState(() => _targetKg = t),
          onRate: (r) => setState(() => _rate = r),
        ),
        const SizedBox(height: 14),

        // Adaptive maintenance — learns your real TDEE from your data.
        _AdaptiveCard(
          weighIns: weighIns,
          assumedIntake: intakeTarget,
          calculatedMaintenance: result.maintenanceCalories,
        ),
      ],
    );
  }

  double _defaultTarget(double current, Goal goal) => switch (goal) {
        Goal.loseWeight => (current - 4).clamp(35, 300),
        Goal.gainWeight => (current + 4).clamp(35, 300),
        Goal.maintainWeight => current,
      };

  Future<void> _logWeighIn(double current) async {
    final controller = TextEditingController(text: current.toStringAsFixed(1));
    final v = context.vita;
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: v.card,
        title: const Text("Today's weight"),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'kg'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: v.brand),
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null && value > 20 && value < 400) {
      await ref.read(weighInsProvider.notifier).add(DateTime.now(), value);
    }
  }
}

// ---------------------------------------------------------------------------

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.weighIns, required this.currentKg});
  final List<WeighIn> weighIns;
  final double currentKg;

  @override
  Widget build(BuildContext context) {
    final change = JourneyMath.netChangeKg(weighIns);
    final v = context.vita;
    return Row(
      children: [
        Expanded(child: _stat(context, 'Current', '${currentKg.toStringAsFixed(1)} kg', v.ink)),
        const SizedBox(width: 10),
        Expanded(child: _stat(context, 'Change', change == null ? '—' : '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} kg',
            change == null ? v.muted : (change <= 0 ? VitaColors.emerald : VitaColors.ember))),
        const SizedBox(width: 10),
        Expanded(child: _stat(context, 'Entries', '${weighIns.length}', v.ink)),
      ],
    );
  }

  Widget _stat(BuildContext context, String label, String value, Color color) {
    return VitaCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: context.monoLabel(size: 9.5)),
          const SizedBox(height: 6),
          Text(value, style: context.mono(size: 17, color: color)),
        ],
      ),
    );
  }
}

class _EmptyTrend extends StatelessWidget {
  const _EmptyTrend({required this.onLog});
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return VitaCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Text('📈', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('Start your trend', style: context.vt.titleMedium),
          const SizedBox(height: 6),
          Text('Log a weigh-in today, then again in a few days. Vita smooths the daily noise into a real trend.',
              textAlign: TextAlign.center, style: TextStyle(color: v.inkSoft, fontSize: 13.5, height: 1.5)),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.weighIns});
  final List<WeighIn> weighIns;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    final smoothed = JourneyMath.smoothedTrend(weighIns);
    final raw = [for (var i = 0; i < weighIns.length; i++) FlSpot(i.toDouble(), weighIns[i].weightKg)];
    final trend = [for (var i = 0; i < smoothed.length; i++) FlSpot(i.toDouble(), smoothed[i])];
    final values = weighIns.map((w) => w.weightKg).toList();
    final minY = (values.reduce((a, b) => a < b ? a : b) - 1);
    final maxY = (values.reduce((a, b) => a > b ? a : b) + 1);

    return VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionLabel('Weight trend'),
              const Spacer(),
              _legend(context, 'Logged', v.muted),
              const SizedBox(width: 12),
              _legend(context, 'Trend', v.brand),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: v.lineSoft, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 34, interval: ((maxY - minY) / 2).clamp(1, 1000),
                      getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0),
                          style: TextStyle(color: v.muted, fontSize: 10)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: raw, isCurved: false, color: v.muted.withOpacity(0.5),
                    barWidth: 1.5, dotData: FlDotData(
                      show: true,
                      getDotPainter: (s, _, __, ___) => FlDotCirclePainter(radius: 2.5, color: v.muted),
                    ),
                  ),
                  LineChartBarData(
                    spots: trend, isCurved: true, curveSmoothness: 0.3,
                    gradient: const LinearGradient(colors: [VitaColors.emerald, VitaColors.lime]),
                    barWidth: 3.5, dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [VitaColors.emerald.withOpacity(0.18), VitaColors.emerald.withOpacity(0)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11.5, color: context.vita.muted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SimulatorCard extends StatelessWidget {
  const _SimulatorCard({
    required this.currentKg,
    required this.targetKg,
    required this.rate,
    required this.weeks,
    required this.date,
    required this.dailyDelta,
    required this.intakeTarget,
    required this.onTarget,
    required this.onRate,
  });
  final double currentKg;
  final double targetKg;
  final double rate;
  final double? weeks;
  final DateTime? date;
  final double dailyDelta;
  final double intakeTarget;
  final ValueChanged<double> onTarget;
  final ValueChanged<double> onRate;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    final lo = (currentKg - 20).clamp(35.0, 300.0);
    final hi = (currentKg + 20).clamp(35.0, 300.0);
    final dateStr = date != null ? DateFormat('MMM d, yyyy').format(date!) : '—';
    final weeksStr = weeks == null ? '—' : (weeks == 0 ? 'now' : '≈ ${weeks!.ceil()} wk');

    return VitaCard(
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 18, color: v.brand),
              const SizedBox(width: 8),
              Text('Goal simulator', style: TextStyle(fontWeight: FontWeight.w800, color: v.ink, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Target weight'),
                  const SizedBox(height: 2),
                  Text('${targetKg.toStringAsFixed(1)} kg', style: context.mono(size: 26)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SectionLabel('Arrives'),
                  const SizedBox(height: 2),
                  Text(dateStr, style: context.mono(size: 17, color: v.brand)),
                ],
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: v.brand,
              inactiveTrackColor: v.lineSoft,
              thumbColor: v.brand,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: targetKg.clamp(lo, hi),
              min: lo,
              max: hi,
              onChanged: (val) => onTarget(double.parse(val.toStringAsFixed(1))),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${lo.toStringAsFixed(0)} kg', style: context.mono(size: 11, color: v.muted)),
              Text(weeksStr, style: context.mono(size: 11, color: v.muted)),
              Text('${hi.toStringAsFixed(0)} kg', style: context.mono(size: 11, color: v.muted)),
            ],
          ),
          const SizedBox(height: 14),
          const SectionLabel('Pace'),
          const SizedBox(height: 8),
          VitaSegmented<double>(
            value: rate,
            onChanged: onRate,
            segments: const [
              VitaSegment(0.25, '0.25 kg/wk'),
              VitaSegment(0.5, '0.5 kg/wk'),
              VitaSegment(1.0, '1 kg/wk'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _pill(context, '${dailyDelta > 0 ? '+' : ''}${dailyDelta.round()}', 'kcal/day', VitaColors.ember)),
              const SizedBox(width: 10),
              Expanded(child: _pill(context, '${intakeTarget.round()}', 'intake target', v.brand)),
              const SizedBox(width: 10),
              Expanded(child: _pill(context, rate.toString(), 'kg/week', v.ink)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String n, String l, Color c) {
    final v = context.vita;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(color: v.isDark ? v.lineSoft : const Color(0xFFF4F2E8), borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(n, style: context.mono(size: 16, color: c)),
          const SizedBox(height: 2),
          Text(l, textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: v.muted)),
        ],
      ),
    );
  }
}

class _AdaptiveCard extends StatelessWidget {
  const _AdaptiveCard({
    required this.weighIns,
    required this.assumedIntake,
    required this.calculatedMaintenance,
  });
  final List<WeighIn> weighIns;
  final double assumedIntake;
  final double calculatedMaintenance;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    double? adaptive;
    if (weighIns.length >= 2) {
      final change = JourneyMath.netChangeKg(weighIns);
      final days = weighIns.last.date.difference(weighIns.first.date).inDays;
      if (change != null && days > 0) {
        adaptive = JourneyMath.adaptiveMaintenance(
            intakeKcal: assumedIntake, weightChangeKg: change, days: days);
      }
    }
    return VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 17, color: v.brand),
              const SizedBox(width: 8),
              Text('Adaptive maintenance', style: TextStyle(fontWeight: FontWeight.w800, color: v.ink, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: v.brand.withOpacity(0.14), borderRadius: BorderRadius.circular(99)),
                child: Text('SMART', style: context.monoLabel(size: 9, color: v.brandDeep)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Calculated'),
                    Text('${calculatedMaintenance.round()}', style: context.mono(size: 22)),
                    Text('from the formula', style: TextStyle(fontSize: 11, color: v.muted)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: v.muted),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SectionLabel('Learned'),
                    Text(adaptive == null ? '—' : '${adaptive.round()}',
                        style: context.mono(size: 22, color: v.brand)),
                    Text('from your data', style: TextStyle(fontSize: 11, color: v.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            adaptive == null
                ? 'Log a few weigh-ins over a week or two and Vita will learn your real maintenance — the number a static calculator can never know.'
                : 'Based on your logged trend and target intake, your body is holding to roughly ${adaptive.round()} kcal — we tune your plan to the truth, not just the formula.',
            style: TextStyle(color: v.inkSoft, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
